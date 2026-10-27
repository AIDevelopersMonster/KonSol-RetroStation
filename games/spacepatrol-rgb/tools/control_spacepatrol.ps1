#requires -Version 7.0
# RS-006 SPACE PATROL: FT2232 UART B, 115200 8N1, no FPGA programming.
[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^COM[0-9]+$')][string]$PortName)
$ErrorActionPreference='Stop'
if(-not $IsWindows){throw 'Windows-only keyboard controller'}
if(-not ('RS006Key' -as [type])){
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class RS006Key {
  [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int key);
}
'@
}
function down([int]$vk){([int][RS006Key]::GetAsyncKeyState($vk) -band 0x8000) -ne 0}
$port=[System.IO.Ports.SerialPort]::new($PortName,115200,[System.IO.Ports.Parity]::None,8,[System.IO.Ports.StopBits]::One)
$port.DtrEnable=$false;$port.RtsEnable=$false
$held=@{left=$false;right=$false;fire=$false}
$last=@{}
$keys=@(@(0x50,'p'),@(0x52,'r'),@(0x31,'1'),@(0x32,'2'),@(0x33,'3'),@(0x34,'4'))
function updateHeld([string]$id,[bool]$value,[string]$downChar,[string]$upChar){
    if($held[$id] -ne $value){
        $port.Write($(if($value){$downChar}else{$upChar}))
        $held[$id]=$value
    }
}
try{
    $port.Open()
    Write-Host "RS006_UART_READY=$PortName 115200 8N1" -ForegroundColor Green
    Write-Host 'A/D or Left/Right: move | F/Space: fire | P: play | R: reset | 1-4: colors | Q/Esc: quit'
    Write-Host 'Focus this PowerShell window.'
    while($true){
        if((down 0x51) -or (down 0x1b)){break}
        updateHeld 'left'  ((down 0x41) -or (down 0x25)) 'a' 'A'
        updateHeld 'right' ((down 0x44) -or (down 0x27)) 'd' 'D'
        updateHeld 'fire'  ((down 0x46) -or (down 0x20)) 'f' 'F'
        foreach($item in $keys){
            $key=[int]$item[0];$cmd=[string]$item[1]
            $value=down $key
            if($value -and -not $last[$key]){$port.Write($cmd)}
            $last[$key]=$value
        }
        Start-Sleep -Milliseconds 15
    }
} finally {
    if($port.IsOpen){$port.Write('x');$port.Close()}
    $port.Dispose()
    Write-Host 'RS006_UART_DISCONNECTED'
}
