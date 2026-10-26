#requires -Version 7.0
<# Download official PONG v1.2 and create a PENDING receipt. NO hardware access. #>
[CmdletBinding()]
param([string]$OutputDirectory = '')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = 'AIDevelopersMonster/Sipeed-FPGA'
$tag = 'pikosol-pong-rgb-v1.2'
$name = 'pikosol_pong_rgb_nano9k.fs'
$hash = '978D9BCFF7C1EF1350F88AF2C603A00B7D3BB6325EA39019CA57CF5091639F96'
$size = 2070601
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $root 'acceptance-local/RS-002'
}
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'Install/configure GitHub CLI (gh) first' }
& gh release download $tag --repo $repo --pattern $name --dir $OutputDirectory --clobber
if ($LASTEXITCODE -ne 0) { throw 'gh release download failed' }
$fs = Join-Path $OutputDirectory $name
if (-not (Test-Path -LiteralPath $fs -PathType Leaf)) { throw 'Release asset missing' }
if ((Get-Item -LiteralPath $fs).Length -ne $size) { throw 'Unexpected binary length' }
$actual = (Get-FileHash -LiteralPath $fs -Algorithm SHA256).Hash
if ($actual -ne $hash) { throw "SHA256 FAIL: $actual" }
Write-Host "RS002_BINARY_PASS: $actual" -ForegroundColor Green

$receiptPath = Join-Path $OutputDirectory 'RS002_RECEIPT.json'
if (Test-Path -LiteralPath $receiptPath) {
    Write-Warning "Existing receipt preserved: $receiptPath"
} else {
    $receipt = [ordered]@{
        protocol = 'RS-002 v0.1'
        status = 'NOT_RUN'
        board_model = 'Sipeed Tang Nano 9K'
        board_sample = ''
        tested_at = ''
        host_os = ''
        tool_versions = ''
        firmware_name = $name
        firmware_sha256 = $hash
        release = "https://github.com/$repo/releases/tag/$tag"
        firmware_size_bytes = $size
        release_hash_check = 'PASS'
        sta_report = ''
        tests = @(
            [ordered]@{ id = 'RS002-T01'; status = 'NOT_RUN'; notes = ''; evidence = @() },
            [ordered]@{ id = 'RS002-T02'; status = 'NOT_RUN'; notes = ''; evidence = @() },
            [ordered]@{ id = 'RS002-T03'; status = 'NOT_RUN'; notes = ''; evidence = @() }
        )
    }
    $receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $receiptPath -Encoding utf8
    Write-Host "RS002_RECEIPT_CREATED: $receiptPath"
}
Write-Host 'NEXT: open docs/acceptance/RS002_PONG_BOARD_PROTOCOL.md and run 3 physical tests.'
