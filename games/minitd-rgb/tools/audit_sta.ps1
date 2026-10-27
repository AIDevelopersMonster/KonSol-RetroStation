#requires -Version 7.0
# KonSol RS-008: read-only audit of original Gowin post-route STA HTML.
# Never changes FPGA configuration, RTL, constraints, or existing games.
[CmdletBinding()]
param(
    [ValidatePattern('^\d{8}_\d{6}$')]
    [string]$BuildStamp = '20261027_211950',
    [ValidatePattern('^[A-Fa-f0-9]{64}$')]
    [string]$ExpectedSha256 = 'AF37412F8C22B3825AD0E2095EEE241F20E0D2CD14FE38C3AD20CB3BAFFF1FB9'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$culture = [Globalization.CultureInfo]::InvariantCulture
$stem = 'konsol_minitd_rgb_nano9k'
$game = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$work = Join-Path $game "build\$BuildStamp\work"
$pnr = Join-Path $work 'impl\pnr'
$fs = Join-Path $pnr "$stem.fs"
$report = Join-Path $pnr "$($stem)_tr_content.html"
if (!(Test-Path -LiteralPath $fs -PathType Leaf)) { throw "RS008_FS_MISSING=$fs" }
if (!(Test-Path -LiteralPath $report -PathType Leaf)) { throw "RS008_STA_REPORT_MISSING=$report" }

$hash = (Get-FileHash -LiteralPath $fs -Algorithm SHA256).Hash.ToUpperInvariant()
if ($hash -cne $ExpectedSha256.ToUpperInvariant()) {
    throw "RS008_HASH_MISMATCH actual=$hash expected=$ExpectedSha256"
}
$bytes = (Get-Item -LiteralPath $fs).Length
if ($bytes -ne 2070601) { throw "RS008_UNEXPECTED_FS_SIZE=$bytes" }
$raw = [IO.File]::ReadAllText($report)

# Extract each named table from native HTML, preserving its <td>/<th> columns.
# Do NOT strip tags globally first: that previously hid Gowin's path slacks.
function Get-GowinTable {
    param([string]$Html, [string]$Anchor)
    $marker = '<a name="' + $Anchor + '">'
    $pos = $Html.IndexOf($marker, [StringComparison]::OrdinalIgnoreCase)
    if ($pos -lt 0) {
        return [pscustomobject]@{ Name=$Anchor; Found=$false; Rows=@() }
    }
    $tail = $Html.Substring($pos + $marker.Length)
    $table = [regex]::Match($tail, '(?is)<table\b[^>]*>(.*?)</table>')
    if (!$table.Success) {
        return [pscustomobject]@{ Name=$Anchor; Found=$false; Rows=@() }
    }
    $rows = [Collections.Generic.List[object]]::new()
    foreach ($row in [regex]::Matches($table.Groups[1].Value, '(?is)<tr\b[^>]*>(.*?)</tr>')) {
        $cells = [Collections.Generic.List[string]]::new()
        foreach ($td in [regex]::Matches($row.Groups[1].Value, '(?is)<t[dh]\b[^>]*>(.*?)</t[dh]>')) {
            $value = [Net.WebUtility]::HtmlDecode(
                [regex]::Replace($td.Groups[1].Value, '(?is)<[^>]+>', ' ')
            )
            $cells.Add(($value -replace '\s+', ' ').Trim())
        }
        if ($cells.Count -gt 0) { $rows.Add($cells.ToArray()) }
    }
    return [pscustomobject]@{ Name=$Anchor; Found=$true; Rows=$rows.ToArray() }
}
function Read-UnsignedStat {
    param($Table,[string]$Name)
    if (!$Table.Found) { return $null }
    $values = [Collections.Generic.List[long]]::new()
    foreach ($row in $Table.Rows) {
        if ($row.Count -ge 2 -and $row[0] -ceq $Name -and $row[1] -match '^\d+$') {
            $values.Add([long]$row[1])
        }
    }
    if ($values.Count -ne 1) { return $null }
    return $values[0]
}
function Get-Slacks {
    param($Table,[string]$FirstHeader,[string]$SecondHeader)
    if (!$Table.Found -or $Table.Rows.Count -lt 1 -or
        $Table.Rows[0].Count -lt 2 -or
        $Table.Rows[0][0] -cne $FirstHeader -or
        $Table.Rows[0][1] -cne $SecondHeader) {
        return [pscustomobject]@{ Status='PARSER_INCONCLUSIVE'; Count=0; MinNs=$null; Worst=@() }
    }
    $values = [Collections.Generic.List[double]]::new()
    $samples = [Collections.Generic.List[string]]::new()
    $malformed = 0
    for ($index=1; $index -lt $Table.Rows.Count; $index++) {
        $r = $Table.Rows[$index]
        if ($r.Count -eq 0) { continue }
        if ($r[0] -notmatch '^\d+$') { continue }
        if ($r.Count -lt 2 -or $r[1] -notmatch '^-?\d+(?:\.\d+)?$') {
            $malformed++
            continue
        }
        $slack = [double]::Parse($r[1], $culture)
        $values.Add($slack)
        if ($samples.Count -lt 5) { $samples.Add(($r -join ' | ')) }
    }
    if ($malformed -gt 0) {
        return [pscustomobject]@{ Status='PARSER_INCONCLUSIVE'; Count=$values.Count; MinNs=$null; Worst=$samples.ToArray() }
    }
    if ($values.Count -eq 0) {
        return [pscustomobject]@{ Status='NO_PATHS_REPORTED'; Count=0; MinNs=$null; Worst=@() }
    }
    $minimum = [double](($values | Measure-Object -Minimum).Minimum)
    return [pscustomobject]@{
        Status= $(if ($minimum -lt 0) { 'FAIL' } else { 'PASS' })
        Count=$values.Count
        MinNs=$minimum
        Worst=$samples.ToArray()
    }
}
function Get-ExceptionStatus {
    param([string]$Html, [string]$Name)
    $marker = '<a name="' + $Name + '_Analysis_Exceptions">'
    $pos = $Html.IndexOf($marker, [StringComparison]::OrdinalIgnoreCase)
    if ($pos -lt 0) { return 'NOT_REPORTED' }
    $sample = $Html.Substring($pos, [Math]::Min(700, $Html.Length-$pos))
    if ($sample -match 'No timing exceptions to report!') { return 'NONE_REPORTED' }
    return 'REVIEW_REQUIRED'
}

$stats = Get-GowinTable $raw 'STA_Tool_Run_Summary'
$setup = Read-UnsignedStat $stats 'Numbers of Setup Violated Endpoints'
$hold = Read-UnsignedStat $stats 'Numbers of Hold Violated Endpoints'
$paths = Read-UnsignedStat $stats 'Numbers of Paths Analyzed'
$endpoints = Read-UnsignedStat $stats 'Numbers of Endpoints Analyzed'

$freq = Get-GowinTable $raw 'Max_Frequency_Report'
$pixelFmax = $null
$serializerFmax = $null
if ($freq.Found) {
    foreach ($r in $freq.Rows) {
        if ($r.Count -ge 4 -and
            $r[2] -match '^(\d+(?:\.\d+)?)\(MHz\)$' -and
            $r[3] -match '^(\d+(?:\.\d+)?)\(MHz\)$') {
            $need = [double]::Parse($r[2].Replace('(MHz)',''),$culture)
            $actual = [double]::Parse($r[3].Replace('(MHz)',''),$culture)
            if ($need -eq 25.2 -and $r[1] -match 'clkdiv_inst') { $pixelFmax = $actual }
            if ($need -eq 126 -and $r[1] -match 'rpll_inst') { $serializerFmax = $actual }
        }
    }
}

$tns = Get-GowinTable $raw 'Total_Negative_Slack_Report'
$tnsRows = [Collections.Generic.List[object]]::new()
$tnsMalformed = !$tns.Found
if ($tns.Found) {
    foreach ($r in $tns.Rows) {
        if ($r.Count -ge 4 -and $r[1] -in @('Setup','Hold')) {
            if ($r[2] -notmatch '^-?\d+(?:\.\d+)?$' -or $r[3] -notmatch '^\d+$') {
                $tnsMalformed=$true
            } else {
                $tnsRows.Add([pscustomobject]@{
                    Clock=$r[0]; Type=$r[1]
                    TnsNs=[double]::Parse($r[2],$culture)
                    ViolatedEndpoints=[int]$r[3]
                })
            }
        }
    }
}
if ($tnsRows.Count -lt 2) { $tnsMalformed=$true }
$pixelSetup = @($tnsRows | Where-Object { $_.Clock -match 'clkdiv_inst' -and $_.Type -eq 'Setup' })
$pixelHold = @($tnsRows | Where-Object { $_.Clock -match 'clkdiv_inst' -and $_.Type -eq 'Hold' })
if ($pixelSetup.Count -ne 1 -or $pixelHold.Count -ne 1) { $tnsMalformed=$true }

$slacks = [ordered]@{}
foreach ($pair in @(
    @('Setup','Setup_Slack_Table','Path Number','Path Slack'),
    @('Hold','Hold_Slack_Table','Path Number','Path Slack'),
    @('Recovery','Recovery_Slack_Table','Path Number','Path Slack'),
    @('Removal','Removal_Slack_Table','Path Number','Path Slack'),
    @('MinimumPulseWidth','MIN_PULSE_WIDTH_TABLE','Number','Slack')
)) {
    $table = Get-GowinTable $raw $pair[1]
    $slacks[$pair[0]] = Get-Slacks $table $pair[2] $pair[3]
}
$exceptions = [ordered]@{}
foreach ($kind in @('Setup','Hold','Recovery','Removal')) {
    $exceptions[$kind] = Get-ExceptionStatus $raw $kind
}

$missing = ($null -eq $setup -or $null -eq $hold -or $null -eq $paths -or
            $null -eq $endpoints -or $null -eq $pixelFmax -or
            $null -eq $serializerFmax -or $tnsMalformed)
$fail = (($null -ne $setup -and $setup -gt 0) -or
         ($null -ne $hold -and $hold -gt 0) -or
         ($null -ne $pixelFmax -and $pixelFmax -lt 25.2) -or
         ($null -ne $serializerFmax -and $serializerFmax -lt 126))
foreach ($row in $tnsRows) {
    if ($row.TnsNs -lt 0 -or $row.ViolatedEndpoints -gt 0) { $fail=$true }
}
foreach ($kind in $slacks.Keys) {
    if ($slacks[$kind].Status -eq 'FAIL') { $fail=$true }
    if ($slacks[$kind].Status -ne 'PASS') { $missing=$true }
}
foreach ($kind in $exceptions.Keys) {
    if ($exceptions[$kind] -ne 'NONE_REPORTED') { $missing=$true }
}
if ($null -ne $paths -and $paths -lt 1) { $missing=$true }
if ($null -ne $endpoints -and $endpoints -lt 1) { $missing=$true }
$verdict = if ($fail) { 'STA_FAIL' }
           elseif ($missing) { 'REVIEW_REQUIRED' }
           else { 'REPORTED_PATHS_PASS_COVERAGE_REVIEW' }

$summary = [ordered]@{
    project='RS-008 MINI TD RGB'
    buildStamp=$BuildStamp
    report=$report
    bitstream=$fs
    sizeBytes=$bytes
    sha256=$hash
    setupViolatingEndpoints=$setup
    holdViolatingEndpoints=$hold
    analyzedPaths=$paths
    analyzedEndpoints=$endpoints
    pixelClockRequiredMHz=25.2
    pixelClockFmaxMHz=$pixelFmax
    serializerClockRequiredMHz=126
    serializerClockFmaxMHz=$serializerFmax
    tns=$tnsRows.ToArray()
    slacks=$slacks
    exceptions=$exceptions
    verdict=$verdict
    coverage='Reported paths only. No independent CDC, asynchronous external UART/reset or complete I/O timing signoff.'
    operatorBoardTest='NOT_RUN'
}
Write-Host "RS008_BITSTREAM_SHA256_PASS=$hash" -ForegroundColor Green
Write-Host "RS008_BUILD=$BuildStamp bytes=$bytes"
Write-Host "RS008_SETUP_VIOLATIONS=$setup"
Write-Host "RS008_HOLD_VIOLATIONS=$hold"
Write-Host "RS008_PIXEL_FMAX_MHZ=$pixelFmax (required=25.2)"
Write-Host "RS008_SERIALIZER_FMAX_MHZ=$serializerFmax (required=126)"
Write-Host "RS008_ANALYZED_PATHS=$paths ENDPOINTS=$endpoints"
foreach ($kind in $slacks.Keys) {
    $v=$slacks[$kind]
    Write-Host "RS008_$($kind.ToUpperInvariant())=$($v.Status) MIN_SLACK_NS=$($v.MinNs) REPORTED=$($v.Count)"
    if ($v.Status -eq 'FAIL') {
        foreach ($line in $v.Worst) { Write-Host "  $line" }
    }
}
foreach ($kind in $exceptions.Keys) {
    Write-Host "RS008_EXCEPTIONS_$($kind.ToUpperInvariant())=$($exceptions[$kind])"
}
Write-Host "RS008_STA_VERDICT=$verdict"

# Preserve independent source evidence for review even when STA fails.
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$stage=Join-Path $work "RS008_STA_EVIDENCE_$stamp"
$archive="$stage.zip"
New-Item -Path $stage -ItemType Directory -Force | Out-Null
try {
    [IO.File]::WriteAllText(
        (Join-Path $stage 'RS008_STA_SUMMARY.json'),
        ($summary | ConvertTo-Json -Depth 8),
        [Text.UTF8Encoding]::new($false)
    )
    Copy-Item -LiteralPath $report -Destination $stage
    foreach ($name in @("$stem.rpt.txt","$stem.log")) {
        $file=Join-Path $pnr $name
        if (Test-Path -LiteralPath $file -PathType Leaf) {
            Copy-Item -LiteralPath $file -Destination $stage
        }
    }
    foreach ($name in @('minitd_rgb.sdc','minitd_rgb.cst')) {
        $file=Join-Path $work "minitd\constraints\$name"
        if (Test-Path -LiteralPath $file -PathType Leaf) {
            Copy-Item -LiteralPath $file -Destination $stage
        }
    }
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive -Force
} finally {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "RS008_STA_EVIDENCE_ZIP=$archive" -ForegroundColor Cyan
Write-Host 'RS008_FPGA_NOT_PROGRAMMED=TRUE'
if ($verdict -ne 'REPORTED_PATHS_PASS_COVERAGE_REVIEW') {
    Write-Warning "RS008_GATE_CLOSED=$verdict; attach evidence ZIP for analysis; DO NOT program FPGA."
} else {
    Write-Warning 'Reported STA paths pass. Inspect constraints and CDC before any SRAM board trial; do not use Flash.'
}
