# RS-006 SPACE PATROL RGB — operator Gowin build candidate

**Observed:** 27 October 2026.  
**Current gate:** **SIM PASS (28 checks) · Gowin bitstream generated · post-route resource and STA review PENDING · BOARD NOT RUN · NOT RELEASED**.

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
| Reported bitstream size | **Not supplied yet** |
| Resources Logic/FF/BSRAM/PLL | **Not supplied yet** |
| Setup/Hold/Recovery/Removal | **Not supplied yet** |

Build script returned both `RS006_CANDIDATE` and `RS006_SHA256` and warned `CANDIDATE ONLY`. This means a `.fs` file was generated, **not** that all post-route timing paths were inspected or that the board passed.

## Independent code-level verification

GitHub Actions [RS-006 simulation run 40446452292](https://github.com/AIDevelopersMonster/KonSol-RetroStation/actions/runs/40446452292) completed with `RS006_SPACEPATROL_TB_PASS checks=28`. This is RTL simulation, not a Gowin fit/STA or hardware test.

## Required before any SRAM programming

1. Independently rehash the **exact** local bitstream and report its byte length.
2. Use `20261027_070050/work/impl/pnr/konsol_spacepatrol_rgb_nano9k.rpt.txt` to extract vendor resource fit and FF/BSRAM/PLL use.
3. Use `20261027_070050/work/impl/pnr/konsol_spacepatrol_rgb_nano9k_tr_content.html` to evaluate all clocks, the Setup/Hold violating-endpoints and TNS summary, min shown Setup/Hold/Recovery/Removal slack, timing exceptions, and evidence (if available) for unconstrained paths/CDC.
4. Only then decide the **2–3 short SRAM-only hardware tests**. No Flash. Do not merge PR #4, publish a `.fs`, or add an RS-006 browser console profile before operator BOARD PASS.

**Source:** operator-provided build output, not independently accessed local `impl/pnr` contents.
