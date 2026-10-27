#requires -Version 7.0
# RS-007: one-shot WASD/arrow key -> FT2232 UART B; never programs FPGA.
[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^COM[0-9]+$')][string]$PortName)
$ErrorActionPreference='Stop'
if(-not $IsWindows){throw 'Windows PowerShell 7 only'}
if(-not ('RS007Keys' -as [type])){
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class RS007Keys {
 [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int key);
}
'@
}
function down([int]$key){([int][RS007Keys]::GetAsyncKeyState($key) -band 0x8000) -ne 0}
$serial=[System.IO.Ports.SerialPort]::new($PortName,115200,[System.IO.Ports.Parity]::None,8,[System.IO.Ports.StopBits]::One)
$serial.DtrEnable=$false;$serial.RtsEnable=$false
$keys=@(@(0x57,'w'),@(0x26,'w'),@(0x41,'a'),@(0x25,'a'),@(0x53,'s'),@(0x28,'s'),@(0x44,'d'),@(0x27,'d'),@(0x50,'p'),@(0x20,'p'),@(0x52,'r'),@(0x31,'1'),@(0x32,'2'),@(0x33,'3'),@(0x34,'4'))
$prior=@{}
try {
 $serial.Open()
 Write-Host "RS007_UART_READY=$PortName 115200 8N1"
 Write-Host "WASD/arrows: direction | P/Space: start | R: reset | 1-4: colors | Q/Esc: exit"
 while($true){
  if((down 0x51) -or (down 0x1b)){break}
  foreach($entry in $keys){
   $vk=[int]$entry[0];$ch=[string]$entry[1];$pressed=down $vk
   if($pressed -and -not $prior[$vk]){$serial.Write($ch)}
   $prior[$vk]=$pressed
  }
  Start-Sleep -Milliseconds 15
 }
}finally{
 if($serial.IsOpen){$serial.Close()}
 $serial.Dispose()
 Write-Host 'RS007_UART_DISCONNECTED'
}
