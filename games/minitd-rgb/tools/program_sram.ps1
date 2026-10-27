#requires -Version 7.0
<#
RS-008 MINI TD RGB: verify the exact operator STA-PASS candidate
and program Tang Nano 9K volatile SRAM via Gowin programmer_cli.exe.
Gowin Programmer SRAM Program operation is "--run 2".
NEVER use run 5/6/36/37, --spiaddr or Flash/erase options here.
No build, no Git writes, no configuration Flash writes.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [string]$ProgrammerCli = '',
    [ValidateRange(1, 32)][int]$CableIndex = 1
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $IsWindows) { throw 'RS008_WINDOWS_POWERSHELL7_REQUIRED' }

# This exact artifact has passed simulation and reported-path Gowin STA.
$fs = Join-Path $PSScriptRoot '..\build\20261027_211950\work\impl\pnr\konsol_minitd_rgb_nano9k.fs'
$fs = (Resolve-Path -LiteralPath $fs -ErrorAction Stop).Path
$expected = 'AF37412F8C22B3825AD0E2095EEE241F20E0D2CD14FE38C3AD20CB3BAFFF1FB9'
$expectedSize = 2070601
$actualSize = (Get-Item -LiteralPath $fs).Length
if ($actualSize -ne $expectedSize) {
    throw "RS008_SIZE_FAIL: expected=$expectedSize actual=$actualSize"
}
$actual = (Get-FileHash -LiteralPath $fs -Algorithm SHA256).Hash
if ($actual -ine $expected) {
    throw "RS008_SHA256_FAIL: expected=$expected actual=$actual"
}
Write-Host "RS008_FS_VERIFIED: $actual ($actualSize bytes)" -ForegroundColor Green

# Use the caller's CLI path, PATH, or a known Gowin Programmer installation.
if ($ProgrammerCli) {
    $cli = (Resolve-Path -LiteralPath $ProgrammerCli -ErrorAction Stop).Path
} else {
    $cmd = Get-Command 'programmer_cli.exe' -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    $cli = if ($null -ne $cmd) { $cmd.Source } else { $null }
    if (-not $cli) {
        $locations = @(
            'C:\Gowin\Gowin_V1.9.9Beta-4_Education\Programmer\bin\programmer_cli.exe',
            'C:\Gowin\Gowin_V1.9.9Beta-4_Education\Programmer\programmer_cli.exe',
            'C:\Gowin\Programmer\bin\programmer_cli.exe',
            'C:\Gowin\Gowin_V1.9.9Beta-4_Education\IDE\bin\programmer_cli.exe'
        )
        $cli = $locations | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
            Select-Object -First 1
    }
    if (-not $cli -and (Test-Path 'C:\Gowin' -PathType Container)) {
        $match = Get-ChildItem -LiteralPath 'C:\Gowin' -Recurse -File -Filter 'programmer_cli.exe' -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($null -ne $match) { $cli = $match.FullName }
    }
}
if (-not $cli -or -not (Test-Path -LiteralPath $cli -PathType Leaf)) {
    throw 'RS008_PROGRAMMER_CLI_NOT_FOUND: re-run with -ProgrammerCli "C:\...\programmer_cli.exe"'
}
Write-Host "RS008_PROGRAMMER=$cli"
Write-Host "RS008_DEVICE=GW1NR-9C CABLE_INDEX=$CableIndex"
Write-Host 'RS008_OPERATION=2 (SRAM ONLY, not Flash)' -ForegroundColor Yellow
Write-Host "RS008_FS=$fs"

# A real invocation may be previewed with -WhatIf. The action is to
# change ONLY the volatile SRAM of the connected Tang Nano 9K.
if ($PSCmdlet.ShouldProcess('Tang Nano 9K GW1NR-9C volatile SRAM',
    "program exact SHA-verified bitstream with Gowin programmer_cli --run 2")) {
    & $cli --device GW1NR-9C --run 2 --fsFile $fs --cable-index $CableIndex
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "RS008_PROGRAMMER_CLI_FAILED_EXIT=$exitCode (verify USB/JTAG and driver)"
    }
    Write-Host 'RS008_PROGRAMMER_CLI_EXIT_0: check HDMI and UART; board PASS not assumed.' -ForegroundColor Green
    Write-Host 'RS008_FLASH_UNTOUCHED_BY_COMMAND: TRUE'
}
