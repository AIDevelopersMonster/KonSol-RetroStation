#requires -Version 7.0
# RS-008 local Windows UART keyboard; read/write COM only, never FPGA JTAG.
[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^COM[0-9]+$')][string]$PortName)
$ErrorActionPreference='Stop'
if(-not $IsWindows){throw 'Windows PowerShell 7 required'}
if(-not ('RS008KeyState' -as [type])){
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class RS008KeyState {
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int key);
}
'@
}
function pressed([int]$key) {
    (([int][RS008KeyState]::GetAsyncKeyState($key)) -band 0x8000) -ne 0
}
$serial=[IO.Ports.SerialPort]::new($PortName,115200,[IO.Ports.Parity]::None,8,[IO.Ports.StopBits]::One)
$serial.DtrEnable=$false;$serial.RtsEnable=$false
$keys=@(
    @(0x31,'1'),@(0x32,'2'),@(0x33,'3'),@(0x34,'4'),
    @(0x54,'t'),@(0x42,'b'),@(0x50,'p'),@(0x20,'p'),
    @(0x52,'r'),@(0x43,'c')
)
$prior=@{}
try {
    $serial.Open()
    Write-Host "RS008_UART_READY=$PortName 115200 8N1" -ForegroundColor Green
    Write-Host '1-4 select pad | T toggle tower | B build | P/Space wave | C palette | R reset | Q/Esc exit'
    while($true){
        if((pressed 0x51) -or (pressed 0x1b)){break}
        foreach($entry in $keys){
            $vk=[int]$entry[0];$ch=[string]$entry[1];$now=pressed $vk
            if($now -and -not $prior[$vk]){$serial.Write($ch)}
            $prior[$vk]=$now
        }
        Start-Sleep -Milliseconds 15
    }
} finally {
    if($serial.IsOpen){$serial.Close()}
    $serial.Dispose()
    Write-Host 'RS008_UART_DISCONNECTED'
}
