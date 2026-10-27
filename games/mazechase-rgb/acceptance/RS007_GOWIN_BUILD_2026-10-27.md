# RS-007 MAZE CHASE RGB — simulation, Gowin fit and STA receipt

**Date:** 27 October 2026  
**Evidence:** operator Windows PowerShell 7 transcript and GitHub Actions.  
**Current status:** **RTL SIM PASS 64 checks**; **Gowin FIT PASS**; **post-route Setup and Hold PASS in both recent candidate reports** (0 violating endpoints, 0 Setup/Hold TNS); **Recovery/Removal, unconstrained path coverage not yet reviewed**; **BOARD NOT RUN**; **NOT RELEASED**.

## Approved for timing audit, NOT YET board-accepted

| Property | Candidate 1 | Candidate 2 (chosen for subsequent preflight) |
| --- | --- | --- |
| Build timestamp | `20261027_124134` | `20261027_124244` |
| FPGA | GW1NR-9C, Sipeed Tang Nano 9K | same |
| Filename | `konsol_mazechase_rgb_nano9k.fs` | same |
| Byte length | 2,070,601 | 2,070,601 |
| Exact SHA-256 | `4160156104FD04C0ADE81B53671190F1404E78FB6E5AA7256CE9FFC01A5E2472` | `9C7228E420385FE8F68C094AD221D075E7A2A22DF6CC28D6D299A858102FFB46` |
| Setup violating endpoints | **0** | **0** |
| Hold violating endpoints | **0** | **0** |
| Pixel/game required clock | 25.200 MHz | 25.200 MHz |
| Pixel/game Actual Fmax | **26.769 MHz** | **26.769 MHz** |
| Setup TNS in reported clock domains | 0.000 | 0.000 |
| Hold TNS in reported clock domains | 0.000 | 0.000 |
| Negative Setup paths in parsed report | none | none |
| Recovery/Removal and path coverage | pending verification | pending verification |
| Operator hardware test | not run | not run |

Fmax minus constrained frequency: 1.569 MHz (approximately 6.2%). These two bitstreams are distinct files even though the reported Fmax and source checksums agree. No root cause for the binary difference is established, and results/physical acceptance must be tied to the **exact chosen SHA-256**. Both builds must not be casually treated as interchangeable.

**Source identity, both candidates:**
- `mazechase_rgb_core.v`: SHA-256 `D05ABB79A8246DC505CDCFE3B5473312C003910DEA65A7FA8429C12FBD98C824`
- HDMI/UART top: SHA-256 `D4F0B79B188B7E5BA21FD8926C0012998C2BAF41A4704EBAC3904F46D5351E11`
- Sipeed-FPGA dependency HEAD: `22c80c18efc3b4bc769de1bf3f18ad8cdf4585b7`.
- Source branch: `feature/rs007-mazechase-rgb`; RTL pipeline revision `20c8df1aa82b78676df250c453a4005147f41ffc`.
- Local timestamped workdirs include `impl/pnr` timing HTML and exact `.fs` files. These artifacts have **not** been uploaded to the repository.

## Simulation

On Windows, the operator repeated:
```text
RS007_MAZECHASE_TB_PASS checks=64
RS007_TB_EXIT_0
```
GitHub Actions [#40481739770](https://github.com/AIDevelopersMonster/KonSol-RetroStation/actions/runs/40481739770): **success**. The Icarus timescale warning is non-fatal; it is not evidence of timing closure.

## Previous STA failures and targeted repairs

| Workdir | SHA-256 prefix | Setup violating endpoints | Pixel-domain Fmax | Critical path |
| --- | --- | ---: | ---: | --- |
| `20261027_113608` | `3FFD481F` | **542** | 21.825 MHz | `player_x/Q -> dots[...]/CE` |
| `20261027_122133` | `9CF88FED` | **87** | 22.631 MHz | `player_y/Q -> score/D, grace/D` |
| `20261027_124134` | `41601561` | **0** | **26.769 MHz** | no negative Setup path in parsed rows |
| `20261027_124244` | `9C7228E4` | **0** | **26.769 MHz** | no negative Setup path in parsed rows |

Stage 1 registered dot-clearing. Stage 2 registered proposed moves and resolved game events, then commits score, lives, enemy/player coordinates and dot clear. Both optimizations retained the original 25.2 MHz video frequency and timing constraints.

**Most recent detailed resource report supplied** is from older `20261027_122133`: Logic 2970/8640 (35%), registers 985/6693 (15%), BSRAM 0%, PLL 1/2; newer candidates' detailed resource reports have **not** been supplied. Do not attribute the old figures to the new files.

## 2026-10-27 — local STA auditor corrected, operator preflight PASS/PENDING

After audit parser fix `52fcb3111bd2b1d28826fe169fe76568736214d9`, the user reran the **local exact-hash auditor** on `20261027_124244`. Its standard output established:

```text
RS007_STA_HTML_ROWS=3557
RS007_SHA256_PASS=9C7228E420385FE8F68C094AD221D075E7A2A22DF6CC28D6D299A858102FFB46
RS007_BYTES=2070601
RS007_SETUP_VIOLATIONS=0
RS007_HOLD_VIOLATIONS=0
RS007_PIXEL_FMAX_MHZ=26.769
RS007_TNS_NS=0,0,0,0,0,0
RS007_RECOVERY=INCONCLUSIVE MIN_SLACK_NS=
RS007_REMOVAL=INCONCLUSIVE MIN_SLACK_NS=
RS007_STA_VERDICT=ASYNC_REVIEW_REQUIRED
RS007_NO_PROGRAMMING_PERFORMED=TRUE
```

The local evidence archive was created at:
`games/mazechase-rgb/build/20261027_124244/work/RS007_STA_EVIDENCE_20261027_142635.zip`.

**Interpretation:** Setup/Hold reported-path closure is reconfirmed; **Recovery/Removal remain *unparsed*, not failed**. The `ASYNC_REVIEW_REQUIRED` verdict means the asynchronous timing gate is not yet accepted. This transcript contains **no evidence** that those checks failed or passed. The exact archive stays on the operator PC until explicitly uploaded; no content from it has been inspected remotely.

**Next:** inspect the archive's original HTML tables and constraint/report coverage; make a decision about the SRAM-only board gate. Do not run an unnecessary third Gowin build or present the audit parser status as a physical FPGA timing failure.

## Final original HTML STA audit — operator ZIP (2026-10-27)

Source archive: `RS007_STA_EVIDENCE_20261027_142635.zip`, SHA-256 `59C66D4DC794B951D9594C34CD07627F72E2DE69B0E6FD844AC3E045FCB2C117`. The archive contains `konsol_mazechase_rgb_nano9k_tr_content.html`, `.rpt.txt`, PnR log, SDC/CST and original audit JSON. The **binary .fs itself is not in the ZIP**; firmware identity is taken from the operator's separately measured exact SHA and 2,070,601-byte length.

**Original Gowin HTML, independently inspected:** reported paths are all positive; the local audit script's `ASYNC_REVIEW_REQUIRED` was a **parser limitation**, not a Recovery/Removal violation.

| Analysis | Min slack in Gowin first 25 reported paths | Result |
| --- | ---: | --- |
| Setup | **+2.326 ns** | PASS; 0 violating endpoints |
| Hold | **+0.599 ns** | PASS; 0 violating endpoints |
| Recovery | **+0.226 ns** | PASS for reported paths |
| Removal | **+1.764 ns** | PASS for reported paths |
| Minimum Pulse Width | **+2.640 ns** | PASS for 10 listed cases |

Other exact report evidence: `6138` analyzed paths, `3074` analyzed endpoints, `3` falling endpoints; six Setup/Hold TNS rows `0.000`; generated 25.2 MHz video clock **Actual Fmax 26.769 MHz**; 126 MHz domain Actual Fmax **525.803 MHz**. Timing Exceptions section says **No timing exceptions to report!** for Setup, Hold, Recovery, Removal. The base 27 MHz clock says **No timing paths to get frequency of clk_27mhz!**; this is not equivalent to complete asynchronous-I/O timing coverage.

Original `konsol_mazechase_rgb_nano9k.rpt.txt` for selected `124244`: **Logic 2929/8640 (34%)**, **LUT 2590**, ALU 243, SSRAM 16, **registers 1014/6693 (16%)**, BSRAM 0%, DSP 0%, PLL 1/2, CLKDIV 1/8, OSER10 3. Gowin version **V1.9.9 Beta-4 Education**, part **GW1NR-LV9QN88PC6/I5**. The report SDC has only `create_clock -name clk_27mhz -period 37.037 ...`; generated clocks are auto-recognized by Gowin. External UART RX and reset_n are asynchronous and no complete external-input timing/CDC certification is claimed.

**Disposition:** FPGA `20261027_124244` with exact operator SHA `9C7228E420385FE8F68C094AD221D075E7A2A22DF6CC28D6D299A858102FFB46` is **eligible for a limited operator SRAM-only board smoke test** (HDMI/video then UART/gameplay). Do not write Flash. This does not authorize merging the draft PR, creating a GitHub Release, or listing a sixth console profile before BOARD PASS. Preserve the old failed candidates as rejected.

## Operator board acceptance (after reported-path STA PASS)

1. **Completed for reported paths:** Recovery +0.226 ns, Removal +1.764 ns, MPW +2.640 ns; exceptions absent. Full external asynchronous-I/O/CDC coverage remains a documented limitation, not a reason to claim absolute STA certification.
2. Pin exactly **candidate 2** `20261027_124244`, SHA-256 `9C7228E420385FE8F68C094AD221D075E7A2A22DF6CC28D6D299A858102FFB46` for a first hardware trial. Never use the older negative-STA images.
3. If remaining timing checks are satisfactory, operator performs 2–3 **volatile SRAM-only** board checks: HDMI + maze rendering; UART movement, dots/score and both enemies; collision/lives, reset/palettes/restart. No Flash.
4. Record operator board outcome and exact uploaded SHA before merging PR #7, publishing a binary release, or adding sixth browser-console profile. Do not present SIM/FIT/STA as a substitute for board evidence.

**Not a complete CDC/clocking certification. No FPGA Flash programming authorized.**
