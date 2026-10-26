# KonSol RetroStation — RS-005 LIGHT CYCLES RGB v0.1.0

**STATUS: RTL SIM PASS (78 checks; GitHub Actions + Windows PowerShell operator). GOWIN FIT/STA NOT RUN. BOARD NOT RUN. NOT RELEASED.**

A two-player original neon-trail arena game for Sipeed Tang Nano 9K (GW1NR-9C), 640×480 HDMI, native Verilog (no CPU, SD, external RAM or framebuffer). Uses the same Sipeed-FPGA sibling dependency as RS-004 K-BLOCKS for the proven display, clocks, serializer and UART transport.

## MVP

- Arena: **32 × 24 cells**, 16×16 pixels each, two 768-bit trail planes (1536 bits total).
- Both riders move one cell at a fixed frame interval; hitting a wall or either trail ends the round.
- Same destination by both riders is a **draw**. No 180-degree turns.
- P1 W/A/S/D. P2 I/J/K/L. `T` toggles a simple rule-based AI on P2.
- `P` or Space starts the next round, `R` resets the full match, keys 1–4 select palettes.
- First to nine points in scorebar (two glowing bars); no font, soundtrack or historical copyrighted assets.
- **AI is a simple forward/left/right collision-avoidance heuristic**, not search/pathfinding.

## Host verification

With PowerShell 7 and Icarus installed (the script checks `C:\msys64\ucrt64\bin`):

```powershell
Set-Location C:\GitHub\KonSol-RetroStation
git switch feature/rs005-lightcycles-rgb
git pull --ff-only
.\games\lightcycles-rgb\test.ps1
```

**SIM PASS (26 Oct 2026):** GitHub Actions [run 40322493712](https://github.com/AIDevelopersMonster/KonSol-RetroStation/actions/runs/40322493712) completed successfully at source commit `be9c927c1e85a6443f73fd32ca1a85514a92f793`: `RS005_LIGHTCYCLES_TB_PASS checks=78`. The operator independently reported the same 78-check PASS on Windows PowerShell, with `RS005_TB_EXIT_0`. An attempted `git switch -c` reported the branch already existed; actual local branch/commit were not printed, so local source identity is pending confirmation. [Simulation receipt](acceptance/RS005_SIM_2026-10-26.md).

## Gowin (only after SIM PASS)

```powershell
.\games\lightcycles-rgb\build.ps1 -SipeedFpgaRoot C:\GitHub\Sipeed-FPGA
```

This is an **isolated build** and creates a SHA-256-identified candidate `.fs`. Before any programming check PnR resource utilization, all clocks, TNS, setup/hold/recovery/removal, exceptions and unconstrained paths. Never reuse RS-004 SHA or STA.

## Hardware check plan (after successful FIT/STA)

1. SRAM-only JTAG load + stable 640×480 HDMI, two initial heads, colored trails.
2. FT2232 UART B: start, turn without reversing, AI mode and two-human mode; observe at least one collision and score.
3. Draw from a same-cell collision; restart round/reset full score. Document exact SHA, local build and tester observations.

Run keyboard controller:

```powershell
.\games\lightcycles-rgb\tools\control_lightcycles.ps1 -PortName COM10
```

Choose actual UART COM number. This script does not program FPGA. **Do not write Flash.** Stop after 2–3 focused hardware checks if conditions fail; check COM, HDMI, power and constraints before modifying RTL.

## Source and license

Gameplay and integration MIT. Sipeed-FPGA shared video uses upstream SimpleVOut ISC and Gowin IP licensing separately. Sources and bitstreams remain in **KonSol-RetroStation**, without modifying RS-003 / RS-004.

**EN:** Independent two-light-trail game with 32×24 grid, two riders, deterministic game state, wall/trail collision, manual two-player mode and a simple optional opponent. This candidate is **not a released bitstream**.
