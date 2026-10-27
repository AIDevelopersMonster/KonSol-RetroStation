# KonSol RetroStation — RS-006 SPACE PATROL RGB v0.1.0

A native Verilog arcade shooter for **Sipeed Tang Nano 9K / GW1NR-9C** (640×480 HDMI; FT2232 channel B UART 115200 8N1). No RISC-V CPU, framebuffer, external RAM, Flash save data, SD card or external game ROM.

**Game features:** 24 enemies (6×4 formation), an independently controlled spacecraft, two player bullets, one hostile bullet, score, three lives, WIN/LOSS, four palettes and reset/restart. Procedural alien/ship graphics (original designs).

**Controls:** A/D or Left/Right — move; F or Space — fire; P — start/new game; R — reset; 1–4 — colors. The UART protocol uses `a/A`, `d/D`, `f/F` for key press/release, plus `x` for releasing held keys.

## Exact hardware-tested candidate

- Name: `konsol_spacepatrol_rgb_nano9k.fs`
- Size: **2,070,601 bytes**
- SHA-256: **`71005039f565aaa6c8530341b1a1758a29c6582f577e75f2dbd1fbc0ecf0a4fd`**
- Gowin build: `games/spacepatrol-rgb/build/20261027_070050/work`
- Icarus RTL: **28 checks PASS** (GitHub Actions).
- Gowin fit: **2437/8640 Logic (29%)**, 583/6693 Registers (9%), PLL 1/2; 0 BSRAM/DSP.
- Shown STA margins: Setup +4.830 ns; Hold +0.550 ns; Recovery +0.541 ns; Removal +1.115 ns; Setup/Hold violations 0 (not an independent exhaustive timing-coverage/CDC certificate).
- **Board result:** operator reports all requested gameplay works on Tang Nano 9K on 27 October 2026; independent video/telemetry evidence has not yet been received.

[Sources](https://github.com/AIDevelopersMonster/KonSol-RetroStation/tree/main/games/spacepatrol-rgb) · [Board receipt](https://github.com/AIDevelopersMonster/KonSol-RetroStation/blob/main/games/spacepatrol-rgb/acceptance/RS006_BOARD_2026-10-27.md) · [Gowin/STA](https://github.com/AIDevelopersMonster/KonSol-RetroStation/blob/main/games/spacepatrol-rgb/acceptance/RS006_GOWIN_BUILD_2026-10-27.md).

**PROGRAM SRAM ONLY.** The bitstream is board-specific and must be validated by SHA-256 before any JTAG session. Flash programming/erase is not part of this release. Native gameplay source MIT, reused SVO ISC and vendor Gowin IP under their separate terms.