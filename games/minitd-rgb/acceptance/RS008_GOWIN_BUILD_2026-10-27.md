# RS-008 MINI TD RGB — Gowin candidate and STA gate

**Operator report date:** 27 October 2026. **Disposition: SIM PASS, Gowin BUILD PASS, reported post-route STA PASS (exact build), controlled SRAM-only smoke test permitted; BOARD NOT RUN; NOT RELEASED.**

| Field | Operator output |
| --- | --- |
| Board | Sipeed Tang Nano 9K / GW1NR-9C |
| Candidate build | `20261027_211950` |
| Firmware | `games/minitd-rgb/build/20261027_211950/work/impl/pnr/konsol_minitd_rgb_nano9k.fs` |
| Local SHA-256 | `AF37412F8C22B3825AD0E2095EEE241F20E0D2CD14FE38C3AD20CB3BAFFF1FB9` |
| Core RTL SHA-256 | `BFC61837BDF0BB8BA4C2419731887E804B88E21BD9ECA9846A95F732669B2AD0` |
| HDMI/UART top SHA-256 | `0EBCD6E351F0115C932C249741F046CB1009F0CA9CD7CAD1319DD63867FDF76E` |
| Shared Sipeed-FPGA source commit | `22c80c18efc3b4bc769de1bf3f18ad8cdf4585b7` |
| Icarus simulation | **41 checks PASS**, `RS008_TB_EXIT_0`, operator local and [GitHub Actions run 40558726198](https://github.com/AIDevelopersMonster/KonSol-RetroStation/actions/runs/40558726198) |
| Gowin build | **PASS**; candidate `.fs` exists locally |
| FPGA resources | Resource report not supplied; optional inspection of existing PnR `.rpt.txt` | 
| Post-route timing | **REPORTED_PATHS_PASS_COVERAGE_REVIEW** from exact-hash operator-local audit; full external I/O/CDC coverage not certified |
| Physical board | **NOT RUN** |

Warnings about Icarus `timescale` and `@*` sensitivity to eight words of `enemy_pos` are informational. They do not replace PnR STA or constitute an FPGA defect diagnosis.


## Operator Gowin STA audit, selected build 20261027_211950

The operator ran `games/minitd-rgb/tools/audit_sta.ps1` after the unchanged initial Gowin build. The output pinned the original **SHA-256 `AF37412F8C22B3825AD0E2095EEE241F20E0D2CD14FE38C3AD20CB3BAFFF1FB9`** and **2,070,601 bytes**. The following are reported values, not values guessed from an earlier game's STA:

| Check | Result |
| --- | --- |
| Setup violated endpoints | **0** |
| Hold violated endpoints | **0** |
| Setup minimum of 25 displayed paths | **+4.830 ns** |
| Hold minimum of 25 displayed paths | **+0.550 ns** |
| Recovery minimum of 25 displayed paths | **+0.541 ns** |
| Removal minimum of 25 displayed paths | **+1.115 ns** |
| Minimum pulse width of 10 displayed rows | **+2.640 ns** |
| Pixel 25.200 MHz | Actual Fmax **31.782 MHz** |
| Serializer 126.000 MHz | Actual Fmax **321.890 MHz** |
| Gowin paths / endpoints analyzed | **3306** / **1658** |
| Timing exceptions by analysis type | **NONE_REPORTED**, Setup/Hold/Recovery/Removal |
| Script verdict | **REPORTED_PATHS_PASS_COVERAGE_REVIEW** |

The script generated the read-only archive:
`games/minitd-rgb/build/20261027_211950/work/RS008_STA_EVIDENCE_20261027_213016.zip`
on the operator's Windows PC. That archive **has not been supplied for independent HTML/report verification**. The report-source checks were performed by the operator-local auditor, with exact hash checking of the local `.fs`.

**Engineering inspection before smoke test:** source `minitd_rgb.sdc` is inherited from successful RS-007 and constrains the 27 MHz external clock (`37.037 ns`); Gowin recognizes generated pixel/serializer clocks as evidenced by the report Fmax. The HDMI top uses pixel-clock-only game state and synchronized 126 MHz serializer reset. UART input receiver implements two-flop synchronization. No explicit UART external input delay constraints or full CDC / reset-domain report were supplied; this remains an acknowledged limitation of the experiment.

**Disposition: permit a limited operator-controlled, volatile SRAM-only HDMI/UART test** of exactly the above bitstream, after local SHA-256 check. The positive reported paths are not an exhaustive certification. NEVER program configuration Flash. A successful WebUSB programming exit code alone is not `BOARD PASS`: check on-screen gameplay and controls. No merge, release, or seventh browser profile before operator board acceptance. If the board smoke fails, stop and diagnose instead of altering the source blindly.

## Read-only timing audit

On the operator's existing Windows PowerShell 7 workstation, update the tracked feature branch and run:

```powershell
Set-Location C:\GitHub\KonSol-RetroStation
git pull --ff-only
.\games\minitd-rgb\tools\audit_sta.ps1
```

The auditor pins the exact SHA-256 and 2,070,601-byte bitstream size, reads Gowin's **native HTML table cells** for Setup/Hold violations and slack, Recovery, Removal, Minimum Pulse Width, clock Fmax and TNS, and inspects timing exceptions. It exports `RS008_STA_EVIDENCE_*.zip` containing the original HTML, resources/report files, SDC/CST and machine-readable summary. It never programs the board. If a section is missing or unparseable, `REVIEW_REQUIRED` closes the hardware gate rather than inventing a PASS.

**Next:** perform controlled SRAM-only HDMI/UART smoke testing of the exact operator-verified candidate; optionally attach the existing evidence ZIP to finish independent full-report and resource review. **No merge, no release, no Flash, no seventh browser profile before operator BOARD PASS.**
