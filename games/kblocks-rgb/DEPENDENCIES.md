# RS-004 external dependencies / Внешние зависимости

- **Repository:** [AIDevelopersMonster/Sipeed-FPGA](https://github.com/AIDevelopersMonster/Sipeed-FPGA) — use a sibling checkout, default `C:\GitHub\Sipeed-FPGA`.
- **Parts reused:** `01-PicoRV32/lab04/rtl/lab04_video_clocks.v`, `01-PicoRV32/rtl/uart_rx_8n1.v`, and the pinned Sipeed PicoTiny SVO modules and Gowin clock wrappers. All are copied into an *untracked isolated build directory*; no vendor code is committed to this game.
- **PicoTiny upstream revision:** `c3b795799f23de91982be52db4273a8eea100cdb`. `fetch_picotiny.ps1` generates and verifies its `SOURCE_PIN.txt` and `SOURCE_SHA256.txt`. The K-BLOCKS build refuses an unexpected vendor pin/hash.
- **Sipeed-FPGA reference snapshot inspected during authoring:** commit `f6cf16f461281e17903aa6e11ab0847a785cd6d2` (26 October 2026). `build.ps1` prints the *actual local* Sipeed-FPGA commit for every build; do not assume later revisions are identical.
- **Toolchain:** Windows PowerShell 7, Icarus Verilog (`iverilog` and `vvp`), Gowin V1.9.9 Beta-4 Education or compatible, with `gw_sh.exe`.
- **Board:** Sipeed Tang Nano 9K / GW1NR-9C only; original RS-003 pin map. This code is **SOURCE CANDIDATE** until hardware acceptance.

## Setup from scratch / Установка

```powershell
Set-Location C:\GitHub
git clone https://github.com/AIDevelopersMonster/KonSol-RetroStation.git
git clone https://github.com/AIDevelopersMonster/Sipeed-FPGA.git
Set-Location .\Sipeed-FPGA
.\01-PicoRV32\lab04\tools\fetch_picotiny.ps1
Set-Location ..\KonSol-RetroStation
.\games\kblocks-rgb\test.ps1
.\games\kblocks-rgb\build.ps1 -SipeedFpgaRoot ..\Sipeed-FPGA
```

If a repository exists already, use `git pull` only after checking your local changes. Do not rewrite the working PiKoSoL/PONG/BREAKOUT implementations. After synthesis, inspect the exact SHA-256-bound full STA report and program the FPGA SRAM only; never flash automatically.
