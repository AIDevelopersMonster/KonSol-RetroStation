# KonSol RetroStation — RS-008 MINI TD RGB v0.1.0

An original standalone tower-defense game in native Verilog for the **Sipeed Tang Nano 9K / GW1NR-9C**. HDMI 640×480 (25.2 MHz pixel clock), UART 115200 8N1 (FT2232 channel B). **FPGA volatile SRAM only**; no CPU, external RAM, ROM, SD or Flash saves.

## Правила / Rules

Five increasingly difficult waves of 4, 5, 6, 7 and 8 enemies travel along a fixed 24×16 tile-map route. Protect your base, initially **12 HP**. Each enemy reaching the exit costs one HP; reducing base HP to zero is defeat. Survive all five waves with HP remaining to win.

Four fixed build pads, initially **12 credits**. Select a pad with `1`–`4`; `T` switches the tower type; `B` builds (once per pad, if funded). Basic tower costs **3 credits**, does **1 damage**, range 4 tiles; heavy tower costs **5**, does **2 damage**, range 5 tiles but shoots every other step. Auto-targeting prioritizes the furthest-advanced in-range enemy. Each kill awards **1 credit**.

`P` or Space launches the first/next wave, `C` cycles four palettes, `R` fully resets. The Windows local UART controller quits with `Q` or Escape. HDMI shows the route, towers, enemies, HP/credit/wave/kill meters and current-game state.

## Exact board-tested candidate

- Name: `konsol_minitd_rgb_nano9k.fs`
- Size: **2,070,601 bytes**
- SHA-256: **`AF37412F8C22B3825AD0E2095EEE241F20E0D2CD14FE38C3AD20CB3BAFFF1FB9`**
- Gowin build: `games/minitd-rgb/build/20261027_211950/work`.
- Source core SHA-256: `BFC61837BDF0BB8BA4C2419731887E804B88E21BD9ECA9846A95F732669B2AD0`.
- CI RTL: **41 checks PASS**.
- Gowin reported STA: Setup/Hold violating endpoints **0/0**; min sampled Setup +4.830 ns, Hold +0.550 ns, Recovery +0.541 ns, Removal +1.115 ns, minimum pulse width +2.640 ns; 25.2 MHz domain actual Fmax 31.782 MHz. This is not exhaustive external I/O or CDC certification.
- Physical board: **operator-reported PASS, 27 October 2026**. Independent video, telemetry or long-term test not attached.

[Source](https://github.com/AIDevelopersMonster/KonSol-RetroStation/tree/main/games/minitd-rgb) · [Board acceptance](https://github.com/AIDevelopersMonster/KonSol-RetroStation/blob/main/games/minitd-rgb/acceptance/RS008_BOARD_2026-10-27.md) · [STA](https://github.com/AIDevelopersMonster/KonSol-RetroStation/blob/main/games/minitd-rgb/acceptance/RS008_GOWIN_BUILD_2026-10-27.md)

**PROGRAM SRAM ONLY.** Check the SHA-256 before programming. Never use the Flash program or erase commands. Original game RTL MIT, reused SVO ISC and Gowin vendor IP under separate terms.
