# RS-008 MINI TD RGB v0.1.0 — original FPGA tower defense candidate

**STATUS: RTL SIM PASS 41 checks (GitHub Actions #40558530333); Gowin FIT/STA NOT RUN; BOARD NOT RUN; NOT RELEASED.**

Native Verilog for Sipeed Tang Nano 9K / GW1NR-9C. HDMI 640x480 at pixel clock 25.2 MHz; FT2232 UART B 115200 8N1; SRAM-only bitstream. No processor, external RAM, ROM or frame buffer.

## Gameplay and controls

- 24x16 logical board, original five-segment route, 4 fixed tower pads, 2 tower types.
- 5 waves (4/5/6/7/8 spawned enemies), up to 8 tracked enemies in parallel; base has 12 health units.
- 12 starting credits. Select pads **1,2,3,4**; toggle light (3 credits) / heavy (5 credits) with **T**; build with **B**.
- Light turret: 1 damage, radius Manhattan <=4, each step. Heavy: 2 damage, radius <=5, every other step.
- Each kill yields 1 credit. Towers seek the most advanced in-range enemy. Serial target scan: 8 entries per tower, one read/comparison per pixel clock.
- **P** or Space starts a wave when READY; **R** fully resets; **C** rotates color palette. Between waves P advances. Five cleared waves = WIN; zero base health = LOSS.
- Visual display: route, pads, enemies, green/yellow/purple tower kinds, active-pad outline, flash, top resource bars (HP, credits, wave, kills), bottom status bar.

**Design boundary:** fixed build pads and route; no mouse, BFS, SD, nonvolatile scores, sound, or full tower placement grid. The operator may pick pads/tower types with the keyboard alone. No repeated changes to known-good 6 games.

## Independent simulation

```powershell
Set-Location C:\GitHub\KonSol-RetroStation
git fetch origin
git switch feature/rs008-mini-td-rgb
git pull --ff-only
.\games\minitd-rgb\test.ps1
```

Expect `RS008_MINITD_TB_PASS checks=N` and `RS008_TB_EXIT_0` only after complete simulation. Run CI independent check.

## Pinned isolated Gowin build, after SIM PASS

```powershell
.\games\minitd-rgb\build.ps1 -SipeedFpgaRoot C:\GitHub\Sipeed-FPGA
```

No SRAM or Flash operations. Capture the exact .fs SHA-256, byte count, logic/FF/BSRAM/PLL, clock domains and post-route Setup/Hold/Recovery/Removal. Do not alter SDC to hide violations.

## Hardware gate after full timing review

1. SRAM-only JTAG load; HDMI stable, 24x16 route + 4 tower pads visible.
2. UART: select pad 1, build B, toggle T, select pad 2, build B, start P, verify waves/targeting/resources.
3. Win/lose/reset + palettes; when result passes operator tests, publish one exact hashed bitstream and append 7th browser profile. Never merge/release based merely on SIM.

**Stop condition:** if 2-3 focused FPGA tests fail, diagnose clocks, UART, HDMI, STA and source before repeating builds. Do not write configuration Flash.

**License:** original Verilog MIT; shared SimpleVOut ISC; Gowin IP vendor terms.
