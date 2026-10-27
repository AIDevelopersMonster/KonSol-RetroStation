# KonSol RetroStation — RS-007 MAZE CHASE RGB v0.1.0

Original maze-chase arcade game implemented in native Verilog for **Tang Nano 9K / GW1NR-9C**. HDMI 640×480 at 25.2 MHz; UART FT2232 B at 115200 8N1; **SRAM-only** configuration.

**Gameplay:** 28×24 labyrinth, 455 energy dots, three lives, score, two adversaries (wall-following patrol and greedy Manhattan-axis chaser), four color palettes, WIN/LOSS and restart. All graphics and gameplay logic are original. No RISC-V CPU, external RAM, SD, framebuffer, commercial arcade ROM or Flash saves.

**Keys:** W/A/S/D or arrow keys change direction, P/Space begins a game, R resets, 1–4 changes palette. Exit local PowerShell controller with Q/Esc.

## Exact operator-tested binary

- Filename: `konsol_mazechase_rgb_nano9k.fs`
- Size: **2,070,601 bytes**
- SHA-256: **`9C7228E420385FE8F68C094AD221D075E7A2A22DF6CC28D6D299A858102FFB46`**
- Windows Gowin build: `games/mazechase-rgb/build/20261027_124244/work`.
- GitHub CI / Icarus Verilog: **64 checks PASS**.
- Gowin resources: Logic **2929/8640 (34%)**; Registers **1014/6693 (16%)**; PLL 1/2.
- Reported STA: **0 Setup/Hold violating endpoints**; sampled minimum Setup +2.326 ns, Hold +0.599 ns, Recovery +0.226 ns, Removal +1.764 ns, MPW +2.640 ns; 25.2 MHz domain Fmax **26.769 MHz**. No exhaustive asynchronous external I/O or CDC certification is claimed.
- **Operator hardware report (27 October 2026):** user reports **«Все работает»**, confirming physical game functionality in general, without independent per-command telemetry, video, or soak test.

[RTL and build](https://github.com/AIDevelopersMonster/KonSol-RetroStation/tree/main/games/mazechase-rgb) · [Operator acceptance](https://github.com/AIDevelopersMonster/KonSol-RetroStation/blob/main/games/mazechase-rgb/acceptance/RS007_BOARD_2026-10-27.md) · [STA review](https://github.com/AIDevelopersMonster/KonSol-RetroStation/blob/main/games/mazechase-rgb/acceptance/RS007_STA_REVIEW_2026-10-27.md)

**PROGRAM SRAM ONLY.** Always verify the binary SHA-256 before programming. Flash writing and erasure are outside this release. Game RTL MIT; SimpleVOut ISC and Gowin vendor IP subject to separate licensing terms.
