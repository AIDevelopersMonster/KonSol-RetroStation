# RS-007 MAZE CHASE RGB v0.1.0 — independent Tang Nano 9K arcade

**STATUS: Icarus RTL SIM PASS (58 checks; GitHub Actions run 40465387709). Gowin FIT/STA NOT RUN. BOARD NOT RUN. NOT RELEASED.**

Original maze-chase game with **28×24** cells and **455 reachable collectible dots** (maze connectivity prechecked), three lives, score, 2 non-identical enemies (simple wall-turning patrol and greedy Manhattan chaser), WIN/LOSS and 4 palettes.

- **Board:** Sipeed Tang Nano 9K / Gowin GW1NR-9C.
- **Display:** 640×480 HDMI at 25.2 MHz pixel clock, source-level reuse of previously tested LAB-04 SVO/PLL.
- **Input:** FT2232 channel B UART at 115200 8N1. WASD or arrow keys; `P`/Space start, `R` reset, `1`–`4` colors. `Q`/Esc closes host controller. One byte changes the desired direction until the next choice.
- **Implementation:** synchronous state updated on accepted video-frame start beats; original tile map generated from cross-wall rules; one mutable dot plane; no processor, commercial ROM/art, external RAM or framebuffer.
- **AI limits:** patrol continues straight with right/left/back fallback; chaser greedily prioritizes the larger coordinate delta. Neither claims optimal pathfinding.
- **Collision:** same tile, head-on exchange, temporary respawn grace, three lives.
- **Victory:** collecting every energy dot. No persistent scores.

## PowerShell 7 simulation (first gate)

```powershell
Set-Location C:\GitHub\KonSol-RetroStation
git fetch origin
git switch feature/rs007-mazechase-rgb
git pull --ff-only
.\games\mazechase-rgb\test.ps1
```

Expect `RS007_MAZECHASE_TB_PASS` only after the testbench finishes without `$fatal`; GitHub CI independently runs Icarus. Do not equate source creation to SIM PASS.

## Isolated Gowin build (only after SIM PASS)

```powershell
.\games\mazechase-rgb\build.ps1 -SipeedFpgaRoot C:\GitHub\Sipeed-FPGA
```

The script creates a timestamped build workdir, verifies pinned SimpleVOut dependencies, and prints candidate `.fs` and SHA-256; **it does not program FPGA SRAM or Flash**. Check Logic/FF/SSRAM/BSRAM/PLL usage and full post-route Setup/Hold/Recovery/Removal and clocks before SRAM testing.

## Local UART keyboard

```powershell
.\games\mazechase-rgb\tools\control_mazechase.ps1 -PortName COM10
```

Use the actual UART COM port. Controller does not program the FPGA.

## Hardware acceptance and stop rule

1. SRAM-only exact SHA-pinned `.fs`; stable 640×480 HDMI, visible maze, character, 2 enemies.
2. Movement and wall collisions, dot removal/score, AI patrol/chaser, loss of life.
3. Reset, 4 palettes, win/loss and restart. Do not merge/release/add WebUSB profile until board acceptance.

One or two days is the bring-up limit; after 2–3 failed obvious board checks, inspect hardware/USB/HDMI/clock/STA rather than rewriting RTL indefinitely. Existing five FPGA games are unchanged.

**Licensing:** original game RTL MIT; reused SVO ISC; Gowin IP subject to its own terms.
