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

## Next acceptance gate (before SRAM-only testing)

1. Confirm Recovery/Removal slacks on the chosen candidate; examine the report for unconstrained or unanalysed paths and external I/O timing coverage. Zero violated Setup/Hold endpoints is meaningful for **analyzed** paths, not proof that every path was constrained.
2. Pin exactly **candidate 2** `20261027_124244`, SHA-256 `9C7228E420385FE8F68C094AD221D075E7A2A22DF6CC28D6D299A858102FFB46` for a first hardware trial. Never use the older negative-STA images.
3. If remaining timing checks are satisfactory, operator performs 2–3 **volatile SRAM-only** board checks: HDMI + maze rendering; UART movement, dots/score and both enemies; collision/lives, reset/palettes/restart. No Flash.
4. Record operator board outcome and exact uploaded SHA before merging PR #7, publishing a binary release, or adding sixth browser-console profile. Do not present SIM/FIT/STA as a substitute for board evidence.

**Not a complete CDC/clocking certification. No FPGA Flash programming authorized.**
