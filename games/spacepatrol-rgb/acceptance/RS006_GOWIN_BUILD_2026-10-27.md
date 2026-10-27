# RS-006 SPACE PATROL RGB — operator Gowin build candidate

**Observed:** 27 October 2026.  
**Current gate:** **SIM PASS (28 checks) · Gowin FIT PASS · shown Setup/Hold paths positive; 0 violating endpoints · full STA review PENDING · BOARD NOT RUN · NOT RELEASED**.

## Candidate identity — from operator's Windows PowerShell output

| Field | Value |
| --- | --- |
| FPGA target | Sipeed Tang Nano 9K / Gowin GW1NR-9C |
| Build command | `games/spacepatrol-rgb/build.ps1 -SipeedFpgaRoot C:\GitHub\Sipeed-FPGA` |
| Working folder | `games/spacepatrol-rgb/build/20261027_070050/work` |
| Bitstream | `impl/pnr/konsol_spacepatrol_rgb_nano9k.fs` |
| **Bitstream SHA-256 (reported)** | `71005039F565AAA6C8530341B1A1758A29C6582F577E75F2DBD1FBC0ECF0A4FD` |
| Game core SHA-256 | `B7F5AEA6CED2F20D604FE80B8AA959EB20CE572306CDC307023B4EBF98D4678E` |
| Top SHA-256 | `982989B0C2DD4EFA0E136A16CD44EEF8C201A4201893E8C643AD03B58C4CD480` |
| Sipeed-FPGA source commit | `22c80c18efc3b4bc769de1bf3f18ad8cdf4585b7` |
| Reported bitstream size | **2,070,601 bytes** (operator `Get-Item`) |
| Resources Logic/FF/BSRAM/PLL | Logic **2437/8640 (29%)**, LUT 2160, ALU 181, SSRAM 16, Register **583/6693 (9%)**, logic FF 582, BSRAM 0%, DSP 0%, PLL **1/2** |
| Setup/Hold/Recovery/Removal | **0 Setup/Hold violating endpoints**; minimum shown Setup **+4.830 ns** and Hold **+0.550 ns** (25-path excerpts). Recovery/Removal section labels, clocks/Fmax, full TNS and unconstrained paths **pending** |

Build script returned both `RS006_CANDIDATE` and `RS006_SHA256` and warned `CANDIDATE ONLY`. This means a `.fs` file was generated, **not** that all post-route timing paths were inspected or that the board passed.

## Independent code-level verification

GitHub Actions [RS-006 simulation run 40446452292](https://github.com/AIDevelopersMonster/KonSol-RetroStation/actions/runs/40446452292) completed with `RS006_SPACEPATROL_TB_PASS checks=28`. This is RTL simulation, not a Gowin fit/STA or hardware test.

## Required before any SRAM programming

1. **Done:** operator independently rehashed the exact bitstream and reported 2,070,601 bytes; the SHA-256 matches the earlier build.
2. **Done:** operator extracted post-route resource fit: 2437/8640 logic, 583/6693 registers, 16 SSRAM, 0% BSRAM/DSP, PLL 1/2.
3. **Partly done:** operator extracted zero Setup/Hold violated endpoints and positive displayed Setup (+4.830 ns) / Hold (+0.550 ns) slacks. A generic grep captured other positive Slack rows, but their Recovery/Removal table labels were **not identified**. Next inspect generated-clock frequency/Fmax, full TNS, Recovery/Removal minima, timing exceptions and any unconstrained paths/CDC evidence.
4. **Hold:** do not program even volatile SRAM until this limited timing gate is reviewed; then 2–3 short operator hardware tests. No Flash. Do not merge PR #4, publish a `.fs`, or add an RS-006 browser console profile before operator BOARD PASS.

**Source:** operator-provided build output, not independently accessed local `impl/pnr` contents.
