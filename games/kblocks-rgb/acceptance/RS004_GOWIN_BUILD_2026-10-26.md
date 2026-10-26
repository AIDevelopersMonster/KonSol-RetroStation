# RS-004 — Gowin build candidate / 26 October 2026

**Evidence class:** OPERATOR BUILD OUTPUT, not verified timing acceptance or physical board acceptance.

## Build identity

- Project: KonSol RetroStation — RS-004 K-BLOCKS RGB v0.1.0.
- Target: **Sipeed Tang Nano 9K / GW1NR-9C** (from versioned Gowin build script).
- Local repository: `C:\GitHub\KonSol-RetroStation`; branch `feature/rs004-kblocks-rgb`.
- Script: `games/kblocks-rgb/build.ps1 -SipeedFpgaRoot C:\GitHub\Sipeed-FPGA`.
- Reused Sipeed-FPGA source checkout commit reported by the script: `22c80c18efc3b4bc769de1bf3f18ad8cdf4585b7`. Pinned SVO dependency was checked by the script.
- Local build directory: `games/kblocks-rgb/build/20261026_125847/work`.
- Candidate: `impl/pnr/konsol_kblocks_rgb_nano9k.fs`.
- Candidate SHA-256 (reported by operator): `F842B196CB4A56E0C18DEF1C471CBDDC82F59F0B552A27F553FDFF9692BBDC4E`.
- Bitstream size: **2,070,601 bytes**, reported by the read-only SHA-256 inspection script.
- Git identity of the exact KonSol source snapshot: **not independently recorded in the build output**. A later branch HEAD must not be retroactively treated as the build identity.
- The operator reported successful completion of Gowin `run all` with a generated `.fs`, so the **build/generation step completed**. This is not by itself evidence of positive timing margins.

## PnR resource report (operator excerpt, same candidate directory)

The read-only inspector verified the candidate SHA-256 against the expected hash and found the report files in the same `impl/pnr` directory.

| Resource | PnR report excerpt | Comment |
| --- | --- | --- |
| Logic | **3561 / 8640 = 42%** (report rounding) | Fits within device logic budget |
| LUT | 3333 | Subtotal: LUT/ALU/ROM16 = 3465 |
| ALU | 132 | No ROM16 |
| SSRAM (RAM16) | 16 | Internal distributed RAM resource; no external RAM required |
| Registers | **695 / 6693 = 11%** | Includes 694 logic FF |
| Logic FF | **694 / 6480 = 11%** | No inferred latches (`0/6480`) |
| IOLOGIC | 7% | Report excerpt |
| BSRAM | 0% | Not used |
| DSP | 0% | Not used |
| PLL | **1 / 2 = 50%** | One PLL used |

PnR report inventory: `.rpt.txt` (21,200 bytes), `.rpt.html` (29,842 bytes), `_tr_content.html` (502,100 bytes), `.log` (1,818 bytes), `.tr.html` (385 bytes). The operator's report collector generated `RS004_STA_READABLE.txt` and local `RS004_STA_EVIDENCE_20261026_133243.zip`. **These files are local to the operator PC, not yet attached or reviewed here.**

**Resource fit conclusion:** the device resource budget appears sufficient based on the operator's PnR report, but these excerpts do not establish setup/hold/recovery/removal margin or timing constraint coverage.

## Independent earlier acceptance

- Icarus on GitHub Actions and Windows: `RS004_KBLOCKS_TB_PASS checks=53`, `RS004_TB_EXIT_0`.
- [Simulation receipt](RS004_SIM_2026-10-26.md).

## Pending — must NOT be marked PASS from this log

1. Resource utilization has now been extracted (above); the full PnR warnings and fit report still require inspection.
2. Examine `impl/pnr/konsol_kblocks_rgb_nano9k_tr_content.html` (or equivalent `.tr`) for all clock domains (input 27 MHz, derived pixel 25.2 MHz and serializer 126 MHz), setup/hold violations, recovery/removal, exceptions, unconstrained paths, generated clocks and minimum pulse widths when available. The published SDC only declares the 27 MHz input clock; **review whether generated clocks are recognized automatically**.
3. Rehash the exact candidate before later SRAM programming and preserve the PnR/STA report alongside the SHA.
4. Board tests (HDMI, keyboard + cleared row, top-out/restart) **NOT RUN**.

**Release gate:** SIM PASS does not imply FIT/STA PASS; no GitHub firmware asset, no browser-loader profile, and **no Flash programming**.
