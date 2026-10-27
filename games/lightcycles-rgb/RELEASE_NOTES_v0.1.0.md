# KonSol RetroStation — LIGHT CYCLES RGB v0.1.0 (RS-005)

Native two-player FPGA game for **Sipeed Tang Nano 9K / GW1NR-9C**. HDMI 640×480, UART 115200 8N1, original Verilog gameplay without RISC-V CPU or external RAM.

**Board acceptance:** on 27 October 2026 the operator confirmed all 3 practical test scenarios: two visible and controllable light trails, collisions/score and AI/manual mode, restart/reset and four palettes. This is operator-reported physical evidence, not an independent automated hardware certification.

**Game:** 32×24 cells, two trails, walls/trail collisions, simultaneous-cell tie, scoreboard, simple AI opponent. P1 W/A/S/D; P2 I/J/K/L; P begins new round; R resets match; T toggles AI; 1–4 palettes.

## Exact released candidate

- File: `konsol_lightcycles_rgb_nano9k.fs`
- Size: **2070601 bytes**
- SHA-256: **`018f5dfaacf7215039c17cc63c115172463bec554d05cb71c236b5606b315712`**

```text
018f5dfaacf7215039c17cc63c115172463bec554d05cb71c236b5606b315712
```

- Build: `games/lightcycles-rgb/build/20261026_185436/work`
- Gowin: Logic 6513/8640 (76%), FF 2034/6480, SSRAM 16, PLL 1/2.
- Gowin sampled STA minima: Setup +1.630 ns, Hold +0.550 ns, Recovery +0.206 ns, Removal +0.867 ns. Setup/Hold TNS 0, endpoints violated 0. Exhaustive unconstrained-path/CDC audit not claimed.
- Icarus Verilog: **78 self-checking checks PASS**.
- [Operator board acceptance](https://github.com/AIDevelopersMonster/KonSol-RetroStation/blob/main/games/lightcycles-rgb/acceptance/RS005_BOARD_2026-10-27.md)
- [STA receipt](https://github.com/AIDevelopersMonster/KonSol-RetroStation/blob/main/games/lightcycles-rgb/acceptance/RS005_STA_2026-10-27.md)

**SAFETY:** volatile SRAM-only; no FPGA Flash. Releases and browser consoles must verify SHA-256 and byte length before programming. Original code MIT; SVO ISC, Gowin IP/vendor terms separately.
