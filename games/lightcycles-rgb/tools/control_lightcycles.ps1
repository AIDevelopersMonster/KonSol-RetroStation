#requires -Version 7.0
# RS-005: keyboard -> FT2232 UART B. No programming/Flash.
[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^COM[0-9]+$')][string]$PortName)
$ErrorActionPreference='Stop'
if (-not $IsWindows) { throw 'Windows-only keyboard controller' }
if(-not ('RS005Key' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class RS005Key {
 [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int key);
}
'@
}
function down([int]$key) { ([int][RS005Key]::GetAsyncKeyState($key) -band 0x8000) -ne 0 }
$port=[System.IO.Ports.SerialPort]::new($PortName,115200,[System.IO.Ports.Parity]::None,8,[System.IO.Ports.StopBits]::One)
$port.DtrEnable=$false; $port.RtsEnable=$false
$keys=@(
 @(0x57,'w'),@(0x41,'a'),@(0x53,'s'),@(0x44,'d'),
 @(0x49,'i'),@(0x4a,'j'),@(0x4b,'k'),@(0x4c,'l'),
 @(0x50,'p'),@(0x20,'p'),@(0x52,'r'),@(0x54,'t'),
 @(0x31,'1'),@(0x32,'2'),@(0x33,'3'),@(0x34,'4')
)
$prior=@{}
try {
 $port.Open()
 Write-Host "RS005_UART_READY=$PortName 115200 8N1" -ForegroundColor Green
 Write-Host "P1: WASD | P2: IJKL | P/Space: start | T: toggle AI | R: reset | 1-4: palette | Q/Esc: quit"
 Write-Host 'Focus this PowerShell window for keyboard input.'
 while ($true) {
  if((down 0x51) -or (down 0x1B)) { break }
  foreach($p in $keys) {
   $key=[int]$p[0]; $cmd=[string]$p[1]
   $isDown=down $key
   if($isDown -and -not $prior[$key]) {
    $port.Write($cmd)
   }
   $prior[$key]=$isDown
  }
  Start-Sleep -Milliseconds 15
 }
} finally {
 if($port.IsOpen){$port.Close()}
 $port.Dispose()
 Write-Host 'RS005_UART_DISCONNECTED'
}
