# RS-005 LIGHT CYCLES RGB — Gowin build receipt

**Reported:** 26 October 2026. **Status:** **SIM PASS (78 checks) · Gowin bitstream generated · STA PENDING · BOARD NOT RUN · NOT RELEASED.**

## Successful build (not the earlier failed attempt)

The operator ran `games/lightcycles-rgb/build.ps1 -SipeedFpgaRoot C:\GitHub\Sipeed-FPGA` after updating to the resource-optimized gameplay RTL.

| Item | Verified operator output |
| --- | --- |
| Board | Tang Nano 9K / GW1NR-9C |
| Build folder | `games/lightcycles-rgb/build/20261026_185436/work` |
| Candidate | `impl/pnr/konsol_lightcycles_rgb_nano9k.fs` |
| **Bitstream SHA-256** | `018F5DFAACF7215039C17CC63C115172463BEC554D05CB71C236B5606B315712` |
| Gameplay core SHA-256 | `793B76621EEB9B49F2EE23728FF1214E9D5E96446C676C5BF64C9B96DED63311` |
| HDMI/UART top SHA-256 | `05D96E59454076D88B6B346E22CDCC729EED5E8836997ACE7088CFC6FF8B4F86` |
| Sipeed-FPGA checkout | `22c80c18efc3b4bc769de1bf3f18ad8cdf4585b7` |
| Bitstream size | Not supplied in operator build excerpt |
| Resource utilization / STA | Not supplied for this candidate |

**CI:** Optimized RTL commit `9f0ee08d7ef35e432bb723c3a2fb1d5624ca597d` passed Icarus with `RS005_LIGHTCYCLES_TB_PASS checks=78` ([run 40351099620](https://github.com/AIDevelopersMonster/KonSol-RetroStation/actions/runs/40351099620)). The operator's local test also passed all 78 checks.

## Historical failure — superseded

`build/20261026_174635/work/gowin.log` records **ERROR RP0006**, mapping **8995 Logic > 8640** (8778 LUT, 121 ALU and 16 SSRAM), before place-and-route. This file belongs to **the older failed build**, not the successful `20261026_185436` candidate. It must not be used to characterize the resources or timing of the new bitstream.

The resource optimization shares a dynamic trail-memory read port across three sequential AI lookahead directions. Both post-change CI and Gowin bitstream generation were successful, but the amount of logic saved has **not been quantified from the new report**.

## Mandatory next gate

1. Confirm SHA-256 of the exact successful `.fs` and collect the **new** `20261026_185436/work/impl/pnr` resource and timing reports.
2. Check Logic/LUT/ALU/FF/SSRAM/BSRAM/PLL use; all three clocks (27 MHz input, 126 MHz PLL, 25.2 MHz pixel); Setup/Hold TNS and violating endpoint counts; Recovery/Removal minima; and exclusions/unconstrained paths.
3. If the new timing report is acceptable, allow **2–3 controlled SRAM-only** tests on the operator Tang Nano 9K. Hardware result still **NOT RUN**.
4. Do not merge the draft PR, publish an RS-005 binary or add a browser console game profile before board acceptance. Never program FPGA Flash.

To collect the right evidence reproducibly, use `games/lightcycles-rgb/tools/inspect_rs005_sta.ps1` from the same branch. It performs read-only checks and archives logs; it does not decide STA acceptance.
