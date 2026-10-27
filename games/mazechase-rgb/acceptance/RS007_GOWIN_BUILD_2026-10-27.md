# RS-007 MAZE CHASE RGB — Gowin bitstream build receipt

**Date:** 27 October 2026. **Evidence:** operator Windows PowerShell 7 transcript.  
**Status:** RTL SIM PASS (58 checks) · **Gowin BUILD/FIT PASS** · **post-route Setup FAIL (542 endpoints)** · Hold summary PASS · BOARD NOT RUN · NO RELEASE. **DO NOT PROGRAM EVEN SRAM** before new positive Setup report.

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
| Byte size | **2,070,601 bytes** (operator Get-Item) |
| PnR resources | Logic **2984/8640 (35%)**; LUT **2645**; ALU **243**; SSRAM **16**; registers **974/6693 (15%)**, logic FF **973**; BSRAM **0%**, DSP **0%**, PLL **1/2** |
| Post-route STA | **25.2 MHz domain FAIL**: Fmax **21.825 MHz**, Setup violating endpoints **542**, Setup TNS **-2159.111 ns**, worst listed Setup slack **-6.136 ns**; Hold violating endpoints **0**; 126 MHz domain Fmax 525.803 MHz |
| Timing/coverage details pending | Worst path **From/To** endpoints not provided by operator's filtered row output. Recovery/Removal minima and unconstrained path coverage not supplied. |

The prior failed build `20261027_111356` aborted in the **Gowin parser**, not due to Logic overflow: EX3132/EX3863 on lines 265/292 of the gameplay RTL. The minimal Verilog disambiguation commit `5be8b2b9959be48dd5db96def1051cbf90e29359` fixed the lexical issue. The successful operator build is the **new** `113608` candidate, not the old `111356` failed workdir.

## Simulation

Windows operator reported `RS007_MAZECHASE_TB_PASS checks=58` and `RS007_TB_EXIT_0` using the fixed RTL. GitHub Actions run [40472815376](https://github.com/AIDevelopersMonster/KonSol-RetroStation/actions/runs/40472815376) also succeeded for the parser-fix commit. Non-fatal Icarus warning noted: missing explicit `timescale` in the core.

## Next acceptance gate

1. **Completed:** independent SHA-256 and 2,070,601-byte length check on the exact build 20261027_113608.
2. **Completed:** 35% logic fit and 15% register use; no resource exhaustion.
3. **Blocked:** 542 failing Setup endpoints, TNS -2159.111 ns, WNS -6.136 ns in the 25.2 MHz video/game clock domain. **Actual Fmax 21.825 MHz < required 25.200 MHz**. Do not mask the failure by altering SDC or video resolution.
4. **Next diagnostic:** inspect the **first 10 rows of the post-route Setup Paths Table** (From Node, To Node, Logic Level and Data Delay) in `konsol_mazechase_rgb_nano9k_tr_content.html`. The current operator report printed path Slack without the path endpoint names. Do not speculate which mux or enemy AI branch caused the critical path until this report is recovered.
5. Only after a targeted RTL path optimization, rerun all 58 Icarus tests and Gowin PnR/STA and compare a **new** exact SHA candidate. SRAM-only board tests remain withheld. No Flash; do not merge draft PR #7, publish the old `.fs`, or add a sixth console profile.

**A generated bitstream is not itself a certificate of full timing closure or hardware correctness.**
