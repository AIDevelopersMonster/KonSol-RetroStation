# KonSol RetroStation — K-BLOCKS RGB v0.1.0 (RS-004)

**Sipeed Tang Nano 9K (GW1NR-9C) · standalone Verilog game · HDMI 640×480 · UART 115200 8N1.**

The operator reports **physical FPGA game success on 26 October 2026** ("все отлично все работает"). This is **operator board evidence**; an independent automated hardware certification or screenshot/video evidence is not claimed.

## Features

- 10×20 field, seven 4-cell shapes, clockwise rotation, soft drop and horizontal movement.
- Complete-line clearing and a two-digit line counter, NEXT preview, four palettes, restart and Game Over.
- Independent game logic, not a historical console emulator. No PicoRV32/SD/external RAM, commercial ROM or game graphics.
- HDMI display; UART keys via FT2232 B (115200 8N1).

## Exact released FPGA image

- **File:** `konsol_kblocks_rgb_nano9k.fs`
- **Bytes:** `2070601`
- **SHA-256:** `f842b196cb4a56e0c18def1c471cbddc82f59f0b552a27f553fdff9692bbdc4e`
- **Build:** `games/kblocks-rgb/build/20261026_125847/work/impl/pnr/`
- **Gowin Logic:** 3561/8640 (42%); registers 695/6693 (11%), PLL 1/2; BSRAM 0%.
- **Gowin STA:** setup and hold TNS 0.000, violation endpoints 0 in all three recognized clock domains; 25-path excerpt minima Setup +5.314 ns, Hold +0.550 ns, Recovery +0.541 ns, Removal +0.825 ns. This is not an independent exhaustive STA certification.

**PROGRAM SRAM ONLY.** The release `.fs` targets **Tang Nano 9K**, not 20K/25K or other boards. Do not erase or program FPGA Flash. The SRAM configuration is lost after a power cycle.

## Source and verification

- [RTL / build scripts / PowerShell controller](https://github.com/AIDevelopersMonster/KonSol-RetroStation/tree/main/games/kblocks-rgb)
- [Icarus SIM PASS (53 checks)](https://github.com/AIDevelopersMonster/KonSol-RetroStation/blob/main/games/kblocks-rgb/acceptance/RS004_SIM_2026-10-26.md)
- [Exact candidate PnR/STA receipt](https://github.com/AIDevelopersMonster/KonSol-RetroStation/blob/main/games/kblocks-rgb/acceptance/RS004_STA_2026-10-26.md)
- [Operator board receipt](https://github.com/AIDevelopersMonster/KonSol-RetroStation/blob/main/games/kblocks-rgb/acceptance/RS004_BOARD_2026-10-26.md)

The KonSol RetroStation GitHub Pages console selects among independently tested Pong / Breakout / K-Blocks bitstreams and verifies exact SHA-256 before volatile SRAM programming. It does not combine all games into one FPGA bitstream.

**Licensing:** original K-Blocks RTL and scripts MIT; SimpleVOut ISC; Gowin vendor tools/IP terms apply separately. No third-party game ROMs included.
