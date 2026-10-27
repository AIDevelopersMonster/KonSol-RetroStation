# RS-008 MINI TD RGB — Gowin candidate and STA gate

**Operator report date:** 27 October 2026. **Disposition: BUILD PASS, POST-ROUTE STA PENDING, BOARD NOT RUN, NOT RELEASED.**

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
| FPGA resources / post-route timing | **NOT YET SUPPLIED** |
| Physical board | **NOT RUN** |

Warnings about Icarus `timescale` and `@*` sensitivity to eight words of `enemy_pos` are informational. They do not replace PnR STA or constitute an FPGA defect diagnosis.

## Read-only timing audit

On the operator's existing Windows PowerShell 7 workstation, update the tracked feature branch and run:

```powershell
Set-Location C:\GitHub\KonSol-RetroStation
git pull --ff-only
.\games\minitd-rgb\tools\audit_sta.ps1
```

The auditor pins the exact SHA-256 and 2,070,601-byte bitstream size, reads Gowin's **native HTML table cells** for Setup/Hold violations and slack, Recovery, Removal, Minimum Pulse Width, clock Fmax and TNS, and inspects timing exceptions. It exports `RS008_STA_EVIDENCE_*.zip` containing the original HTML, resources/report files, SDC/CST and machine-readable summary. It never programs the board. If a section is missing or unparseable, `REVIEW_REQUIRED` closes the hardware gate rather than inventing a PASS.

**Next:** inspect the auditor's console output and exact evidence ZIP. If STA is negative, repair only the identified critical path(s) and rerun tests and Gowin. If timing passes, separately inspect clock/reset, asynchronous I/O and coverage before SRAM-only hardware testing. **No merge, no release, no Flash, no seventh browser profile before operator BOARD PASS.**
