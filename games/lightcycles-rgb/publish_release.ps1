#requires -Version 7.0
<#
KonSol RetroStation RS-005 LIGHT CYCLES RGB v0.1.0
Exact operator-tested bitstream release publisher. Dry-run by default.
Does not program FPGA SRAM or Flash. Requires GitHub CLI only with -Publish.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Bitstream,
    [switch]$Publish
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = 'AIDevelopersMonster/KonSol-RetroStation'
$tag = 'konsol-lightcycles-rgb-v0.1.0'
$expectedName = 'konsol_lightcycles_rgb_nano9k.fs'
$expectedHash = '018F5DFAACF7215039C17CC63C115172463BEC554D05CB71C236B5606B315712'
$expectedSize = 2070601
$fs = (Resolve-Path -LiteralPath $Bitstream -ErrorAction Stop).Path

if ((Split-Path -Leaf $fs) -cne $expectedName) {
    throw "STOP: wrong file. Expected $expectedName"
}
$size = (Get-Item -LiteralPath $fs).Length
if ($size -ne $expectedSize) { throw "STOP: wrong size $size, expected $expectedSize" }
$actual = (Get-FileHash -LiteralPath $fs -Algorithm SHA256).Hash
if ($actual -ine $expectedHash) { throw "STOP: SHA-256 mismatch: $actual" }
Write-Host "RS005_RELEASE_LOCAL_IDENTITY_PASS: $actual ($size bytes)" -ForegroundColor Green
if (-not $Publish) {
    Write-Host 'RS005_RELEASE_DRY_RUN: no GitHub changes. Pass -Publish to publish the prerelease.'
    return
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI gh is missing' }
& gh auth status
if ($LASTEXITCODE -ne 0) { throw 'GitHub CLI is not authenticated' }
& gh release view $tag --repo $repo 2>$null
if ($LASTEXITCODE -eq 0) { throw "STOP: existing release $tag; refusing to overwrite" }
$notes = Join-Path $PSScriptRoot 'RELEASE_NOTES_v0.1.0.md'
if (-not (Test-Path -LiteralPath $notes -PathType Leaf)) { throw "Missing release notes: $notes" }
$temp = Join-Path ([IO.Path]::GetTempPath()) ('rs004_release_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp -Force | Out-Null
try {
    $checksums = Join-Path $temp 'SHA256SUMS.txt'
    Set-Content -LiteralPath $checksums -Value ($expectedHash.ToLowerInvariant() + '  ' + $expectedName) -Encoding ascii
    & gh release create $tag $fs $checksums --repo $repo --target main --prerelease `
        --title 'KonSol RetroStation LIGHT CYCLES RGB v0.1.0 | Tang Nano 9K' --notes-file $notes
    if ($LASTEXITCODE -ne 0) { throw 'GitHub release creation failed; inspect tag before retrying' }
    $verify = Join-Path $temp 'redownload'
    New-Item -ItemType Directory -Path $verify | Out-Null
    & gh release download $tag --repo $repo --pattern $expectedName --dir $verify
    if ($LASTEXITCODE -ne 0) { throw 'Remote binary re-download failed' }
    $remote = Join-Path $verify $expectedName
    $downloadHash = (Get-FileHash -LiteralPath $remote -Algorithm SHA256).Hash
    if ($downloadHash -ine $expectedHash) { throw "REMOTE_SHA256_FAIL: $downloadHash" }
    if ((Get-Item -LiteralPath $remote).Length -ne $expectedSize) { throw 'REMOTE_SIZE_FAIL' }
    Write-Host "RS005_REMOTE_RELEASE_SHA256_PASS: $downloadHash" -ForegroundColor Green
    Write-Host "RS005_RELEASE_PUBLISHED: https://github.com/$repo/releases/tag/$tag" -ForegroundColor Green
    Write-Host 'GitHub Pages workflow will publish the exact checked asset after release is published.'
} finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
