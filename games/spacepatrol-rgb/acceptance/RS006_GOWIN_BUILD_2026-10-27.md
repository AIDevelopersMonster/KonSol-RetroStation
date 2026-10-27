# RS-006 SPACE PATROL RGB — operator Gowin build candidate

**Observed:** 27 October 2026.  
**Current gate:** **SIM PASS (28 checks) · Gowin BUILD/FIT PASS · positive sampled Setup/Hold/Recovery/Removal · conditional GO for SRAM-only board testing · BOARD NOT RUN · NOT RELEASED**.

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
| Setup/Hold/Recovery/Removal | **0 Setup/Hold violated endpoints**; minimum shown Setup **+4.830 ns**, Hold **+0.550 ns**, Recovery **+0.541 ns**, Removal **+1.115 ns** (bounded 25-path excerpts) |

Build script returned both `RS006_CANDIDATE` and `RS006_SHA256` and warned `CANDIDATE ONLY`. This means a `.fs` file was generated, **not** that all post-route timing paths were inspected or that the board passed.

## Independent code-level verification

GitHub Actions [RS-006 simulation run 40446452292](https://github.com/AIDevelopersMonster/KonSol-RetroStation/actions/runs/40446452292) completed with `RS006_SPACEPATROL_TB_PASS checks=28`. This is RTL simulation, not a Gowin fit/STA or hardware test.

## Required before any SRAM programming

1. **Done:** operator independently rehashed the exact bitstream and reported 2,070,601 bytes; the SHA-256 matches the earlier build.
2. **Done:** operator extracted post-route resource fit: 2437/8640 logic, 583/6693 registers, 16 SSRAM, 0% BSRAM/DSP, PLL 1/2.
3. **Done for bounded post-route timing gate:** operator extracted Recovery and Removal labeled tables and clock Fmax: 126.000 MHz PLL domain with estimated Actual Fmax **321.890 MHz**, 25.200 MHz pixel/game domain with estimated Actual Fmax **32.051 MHz** (~**27.2%** above 25.2). Shown Setup/Hold/Recovery/Removal minimum slacks all positive. The excerpts show zero Setup/Hold violated endpoints, and displayed TNS rows for 27 MHz and PLL begin at **0.000 ns**. The Setup exceptions subsection says **`No timing exceptions to report!`**. The output was truncated before the entire TNS summary and other exceptions subsections; a complete unconstrained-path/CDC audit was not performed. Vendor notes `No timing paths to get frequency of clk_27mhz!` for the reference clock; do not mistake that statement alone for an Fmax failure.
4. **CONDITIONAL GO for 2-3 brief operator SRAM-only tests** of this exact bitstream, after recomputing exact SHA-256. Keep raw reports for future complete coverage review. Do not merge PR #4, release `.fs`, or register a WebUSB profile until operator BOARD PASS. No FPGA Flash programming.

**Source:** operator-provided build output, not independently accessed local `impl/pnr` contents.
