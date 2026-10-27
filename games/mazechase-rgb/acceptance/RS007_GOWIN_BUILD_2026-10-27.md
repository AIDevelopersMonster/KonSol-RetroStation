# RS-007 MAZE CHASE RGB — Gowin bitstream build receipt

**Date:** 27 October 2026. **Evidence:** operator Windows PowerShell 7 transcript.  
**Status:** RTL SIM PASS (58 checks) · **Gowin BUILD PASS (candidate generated)** · resource report and STA **PENDING** · BOARD NOT RUN · NO RELEASE.

## Pinned exact candidate

| Property | Operator output |
| --- | --- |
| Target board | Sipeed Tang Nano 9K / GW1NR-9C |
| Build invocation | `games/mazechase-rgb/build.ps1 -SipeedFpgaRoot C:\GitHub\Sipeed-FPGA` |
| Work folder | `games/mazechase-rgb/build/20261027_113608/work` |
| Firmware candidate | `impl/pnr/konsol_mazechase_rgb_nano9k.fs` |
| **Firmware SHA-256** | **`3FFD481F4A203DD159FFBB055ED0D269B57A4E635F68166745F82224535F86DE`** |
| Core source SHA-256 | `2EFDAF49510806AA154940E96AAD6805567DD1530A859145B684BBC7450F6CA0` |
| HDMI/UART top SHA-256 | `D4F0B79B188B7E5BA21FD8926C0012998C2BAF41A4704EBAC3904F46D5351E11` |
| Shared Sipeed-FPGA commit | `22c80c18efc3b4bc769de1bf3f18ad8cdf4585b7` |
| Byte size | Not yet independently printed |
| PnR resource summary and post-route STA | Not yet provided |

The prior failed build `20261027_111356` aborted in the **Gowin parser**, not due to Logic overflow: EX3132/EX3863 on lines 265/292 of the gameplay RTL. The minimal Verilog disambiguation commit `5be8b2b9959be48dd5db96def1051cbf90e29359` fixed the lexical issue. The successful operator build is the **new** `113608` candidate, not the old `111356` failed workdir.

## Simulation

Windows operator reported `RS007_MAZECHASE_TB_PASS checks=58` and `RS007_TB_EXIT_0` using the fixed RTL. GitHub Actions run [40472815376](https://github.com/AIDevelopersMonster/KonSol-RetroStation/actions/runs/40472815376) also succeeded for the parser-fix commit. Non-fatal Icarus warning noted: missing explicit `timescale` in the core.

## Next acceptance gate

1. Recompute the exact `.fs` SHA-256 and size at `20261027_113608/work/impl/pnr`.
2. Inspect `konsol_mazechase_rgb_nano9k.rpt.txt`: Logic, LUT, ALU, RAM16, FF, BSRAM, DSP, PLL.
3. Inspect `konsol_mazechase_rgb_nano9k_tr_content.html`: clocks, constraints versus Actual Fmax, zero violating endpoints, TNS and first-path Setup/Hold/Recovery/Removal slacks; report any missing/unconstrained analysis.
4. After timing gate, conduct **2–3 controlled volatile SRAM-only** operator board checks; no FPGA Flash. Do not merge draft PR #7, upload binary, or add sixth browser console profile until operator BOARD PASS.

**A generated bitstream is not itself a certificate of full timing closure or hardware correctness.**
