#requires -Version 7.0
# KonSol RS-005: Icarus Verilog self-check. Does not program the FPGA.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if (-not (Get-Command iverilog -ErrorAction SilentlyContinue)) {
    $ucrt = 'C:\msys64\ucrt64\bin'
    if (Test-Path (Join-Path $ucrt 'iverilog.exe')) {
        $env:PATH = "$ucrt;$env:PATH"
    }
}
foreach ($cmd in @('iverilog','vvp')) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        throw "Missing $cmd. RS005_SIM_NOT_RUN; install Icarus Verilog."
    }
}
$out = Join-Path $PSScriptRoot 'build\tb'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$exe = Join-Path $out 'lightcycles_tb.out'
& iverilog -g2012 -Wall -s tb_lightcycles_rgb_core -o $exe `
    (Join-Path $PSScriptRoot 'rtl\lightcycles_rgb_core.v') `
    (Join-Path $PSScriptRoot 'tests\tb_lightcycles_rgb_core.v')
if ($LASTEXITCODE -ne 0) { throw 'RS005_IVERILOG_FAIL' }
& vvp $exe
if ($LASTEXITCODE -ne 0) { throw 'RS005_TB_FAIL' }
Write-Host 'RS005_TB_EXIT_0' -ForegroundColor Green
