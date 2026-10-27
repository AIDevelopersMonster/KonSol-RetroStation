#requires -Version 7.0
# RS-007: read-only STA audit and evidence ZIP. No RTL edits or FPGA programming.
[CmdletBinding()]
param(
    [ValidatePattern('^\d{8}_\d{6}$')]
    [string]$BuildStamp = '20261027_124244',
    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string]$ExpectedSha256 = '9C7228E420385FE8F68C094AD221D075E7A2A22DF6CC28D6D299A858102FFB46'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$stem = 'konsol_mazechase_rgb_nano9k'
$game = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$work = Join-Path $game "build\$BuildStamp\work"
$pnr = Join-Path $work 'impl\pnr'
$fs = Join-Path $pnr "$stem.fs"
$report = Join-Path $pnr "$($stem)_tr_content.html"
if (!(Test-Path -LiteralPath $fs -PathType Leaf)) { throw "RS007_FS_MISSING=$fs" }
if (!(Test-Path -LiteralPath $report -PathType Leaf)) { throw "RS007_STA_HTML_MISSING=$report" }
$hash = (Get-FileHash -LiteralPath $fs -Algorithm SHA256).Hash.ToUpperInvariant()
if ($hash -cne $ExpectedSha256.ToUpperInvariant()) {
    throw "RS007_HASH_MISMATCH expected=$ExpectedSha256 actual=$hash"
}
$bytes = (Get-Item -LiteralPath $fs).Length
if ($bytes -ne 2070601) { throw "RS007_UNEXPECTED_FS_SIZE=$bytes" }

$html = [IO.File]::ReadAllText($report)
$html = [regex]::Replace($html, '(?is)<script\b[^>]*>.*?</script>', ' ')
$html = [regex]::Replace($html, '(?is)<style\b[^>]*>.*?</style>', ' ')
$html = [regex]::Replace($html, '(?is)<tr\b[^>]*>', [Environment]::NewLine)
$html = [regex]::Replace($html, '(?is)</(?:h[1-6]|p|table)\s*>', [Environment]::NewLine)
$html = [regex]::Replace($html, '(?is)<br\s*/?>', [Environment]::NewLine)
$html = [regex]::Replace($html, '(?is)</t[dh]\s*>', ' | ')
$html = [regex]::Replace($html, '(?is)<[^>]+>', ' ')
$plain = [Net.WebUtility]::HtmlDecode($html)
$lines = @(
    $plain -split '[\r\n]+' |
        ForEach-Object { ($_ -replace '\s+', ' ').Trim() } |
        Where-Object { $_.Length -gt 0 }
)
function Read-Count([string]$name) {
    $rows = @($lines | Where-Object {
        $_ -match ('^' + [regex]::Escape($name) + '\s*\|\s*\d+\s*(?:\||$)')
    })
    if ($rows.Count -ne 1) { return $null }
    return [int]([regex]::Match($rows[0], '\|\s*(\d+)').Groups[1].Value)
}
function Read-Section([string]$header,[string]$kind) {
    for ($i=0;$i -lt $lines.Count;$i++) {
        if ($lines[$i] -notmatch ('^' + [regex]::Escape($header) + '\s*(?:\|.*)?$')) { continue }
        $lookEnd = [Math]::Min($lines.Count-1,$i+4)
        $look = $lines[$i..$lookEnd] -join ' '
        if ($look -notmatch ('Report Command:\s*report_timing\s+-' + $kind + '\b')) { continue }
        $end = [Math]::Min($lines.Count,$i+2000)
        for ($j=$i+2;$j -lt $end;$j++) {
            if ($lines[$j] -match '^(?:Setup|Hold|Recovery|Removal) (?:Paths Table|Analysis Report)$' -or
                $lines[$j] -match '^(?:Minimum Pulse Width Table|Minimum Pulse Width Report|High Fanout Nets Report|Timing Report By Analysis Type|Timing Exceptions Report)$') {
                $end=$j
                break
            }
        }
        return @($lines[$i..([Math]::Max($i,$end-1))])
    }
    return @()
}
function Check-Async([string]$kind) {
    $table = @(Read-Section "$kind Paths Table" $kind.ToLowerInvariant())
    $analysis = @(Read-Section "$kind Analysis Report" $kind.ToLowerInvariant())
    $section = @($table) + @($analysis)
    if ($section.Count -eq 0) {
        return [pscustomobject]@{status='NOT_FOUND';minSlackNs=$null;pathCount=0;sample=@()}
    }
    $slacks = [Collections.Generic.List[double]]::new()
    foreach ($line in $section) {
        $m = [regex]::Match($line,'^\s*\d+\s*\|\s*(-?\d+(?:\.\d+)?)\s*\|')
        if (!$m.Success) {
            $m = [regex]::Match($line,'^\s*Slack\s*\|\s*(-?\d+(?:\.\d+)?)\s*(?:\||$)')
        }
        if ($m.Success) {
            $slacks.Add([double]::Parse($m.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture))
        }
    }
    $minimum = if ($slacks.Count -gt 0) { ($slacks | Measure-Object -Minimum).Minimum } else { $null }
    $status = if ($slacks.Count -gt 0) {
        if ($minimum -lt 0) { 'FAIL' } else { 'NONNEGATIVE_REPORTED_PATHS' }
    } elseif (($section -join ' ') -match 'Nothing to report!') {
        'NO_PATHS_REPORTED'
    } else { 'INCONCLUSIVE' }
    return [pscustomobject]@{
        status=$status; minSlackNs=$minimum; pathCount=$slacks.Count
        sample=@($section | Select-Object -First 15)
    }
}
$setup=Read-Count 'Numbers of Setup Violated Endpoints'
$hold=Read-Count 'Numbers of Hold Violated Endpoints'
$fmax=$null
foreach ($line in $lines) {
    $m=[regex]::Match($line,'\|\s*25\.200\(MHz\)\s*\|\s*(\d+(?:\.\d+)?)\(MHz\)')
    if ($m.Success) {
        $fmax=[double]::Parse($m.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)
        break
    }
}
$tns=@(
    foreach ($line in $lines) {
        $m=[regex]::Match($line,'\|\s*(?:Setup|Hold)\s*\|\s*(-?\d+(?:\.\d+)?)\s*\|')
        if ($m.Success) {
            [double]::Parse($m.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)
        }
    }
)
$recovery=Check-Async 'Recovery'
$removal=Check-Async 'Removal'
$negativeTns=@($tns | Where-Object { $_ -lt 0 })
$corePass=($null -ne $setup -and $null -ne $hold -and $null -ne $fmax -and
           $setup -eq 0 -and $hold -eq 0 -and $fmax -ge 25.2 -and
           $tns.Count -ge 2 -and $negativeTns.Count -eq 0)
$fail=(!$corePass -or $recovery.status -eq 'FAIL' -or $removal.status -eq 'FAIL')
$needsManual=($recovery.status -ne 'NONNEGATIVE_REPORTED_PATHS' -or
              $removal.status -ne 'NONNEGATIVE_REPORTED_PATHS')
$verdict=if ($fail) { 'FAIL' } elseif ($needsManual) { 'ASYNC_REVIEW_REQUIRED' }
         else { 'REPORTED_PATHS_PASS_COVERAGE_REVIEW' }
$result=[ordered]@{
    board='Tang Nano 9K GW1NR-9C'
    buildStamp=$BuildStamp
    bitstream=$fs
    sha256=$hash
    bytes=$bytes
    setupViolations=$setup
    holdViolations=$hold
    pixelFmaxMHz=$fmax
    requiredPixelClockMHz=25.2
    tnsNs=@($tns)
    recovery=$recovery
    removal=$removal
    verdict=$verdict
    caveat='Reported timing is not proof of all unconstrained paths, reset release, CDC or hardware correctness.'
}
Write-Host "RS007_SHA256_PASS=$hash" -ForegroundColor Green
Write-Host "RS007_BYTES=$bytes"
Write-Host "RS007_SETUP_VIOLATIONS=$setup"
Write-Host "RS007_HOLD_VIOLATIONS=$hold"
Write-Host "RS007_PIXEL_FMAX_MHZ=$fmax"
Write-Host "RS007_TNS_NS=$($tns -join ',')"
Write-Host "RS007_RECOVERY=$($recovery.status) MIN_SLACK_NS=$($recovery.minSlackNs)"
Write-Host "RS007_REMOVAL=$($removal.status) MIN_SLACK_NS=$($removal.minSlackNs)"
Write-Host "RS007_STA_VERDICT=$verdict"

$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$stage=Join-Path $work "RS007_STA_EVIDENCE_$stamp"
$archive="$stage.zip"
New-Item -Path $stage -ItemType Directory -Force | Out-Null
try {
    [IO.File]::WriteAllText((Join-Path $stage 'RS007_STA_SUMMARY.json'),
        ($result | ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllLines((Join-Path $stage 'RS007_STA_READABLE.txt'),
        [string[]]$lines,[Text.UTF8Encoding]::new($false))
    foreach ($name in @("$($stem)_tr_content.html","$stem.rpt.txt","$stem.log")) {
        $source=Join-Path $pnr $name
        if (Test-Path -LiteralPath $source -PathType Leaf) {
            Copy-Item -LiteralPath $source -Destination $stage
        }
    }
    foreach ($name in @('mazechase_rgb.sdc','mazechase_rgb.cst')) {
        $source=Join-Path $work "mazechase\constraints\$name"
        if (Test-Path -LiteralPath $source -PathType Leaf) {
            Copy-Item -LiteralPath $source -Destination $stage
        }
    }
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive -Force
} finally {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "RS007_STA_EVIDENCE_ZIP=$archive" -ForegroundColor Cyan
Write-Host 'RS007_NO_PROGRAMMING_PERFORMED=TRUE'
if ($verdict -ne 'REPORTED_PATHS_PASS_COVERAGE_REVIEW') {
    Write-Warning "RS007_STA_REVIEW_REQUIRED=$verdict"
} else {
    Write-Warning 'Reported paths pass, but timing coverage still requires engineering review.'
}
