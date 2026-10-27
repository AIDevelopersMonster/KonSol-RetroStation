# RS-005 LIGHT CYCLES RGB — Gowin build receipt

**Reported:** 26 October 2026. **Status:** **SIM PASS (78 checks) · Gowin BUILD/FIT PASS · Setup/Hold timing summary PASS · Recovery/Removal + unconstrained-path review PENDING · BOARD NOT RUN · NOT RELEASED.**

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
| Bitstream size | **2,070,601 bytes**, independently rehashed on operator PC |
| Resource utilization | **Logic 6513/8640 (tool rounded 76%), LUT 6271, ALU 146, SSRAM 16, FF 2034/6480, BSRAM 0%, DSP 0%, PLL 1/2** |
| Setup/Hold summary | **0 violating endpoints**; TNS **0.000 ns** for 27, 126 and 25.2 MHz domains |
| Worst shown setup/hold | **+1.630 ns / +0.550 ns** (first 25 paths in each category) |
| 25.2 MHz pixel-domain Fmax | **26.280 MHz** — only **4.3%** over target, narrow margin |
| Recovery / Removal / unconstrained paths | **NOT YET REVIEWED**; omitted from supplied 65-row excerpt |

**CI:** Optimized RTL commit `9f0ee08d7ef35e432bb723c3a2fb1d5624ca597d` passed Icarus with `RS005_LIGHTCYCLES_TB_PASS checks=78` ([run 40351099620](https://github.com/AIDevelopersMonster/KonSol-RetroStation/actions/runs/40351099620)). The operator's local test also passed all 78 checks.

## Historical failure — superseded

`build/20261026_174635/work/gowin.log` records **ERROR RP0006**, mapping **8995 Logic > 8640** (8778 LUT, 121 ALU and 16 SSRAM), before place-and-route. This file belongs to **the older failed build**, not the successful `20261026_185436` candidate. It must not be used to characterize the resources or timing of the new bitstream.

The resource optimization shares a dynamic trail-memory read port across three sequential AI lookahead directions. Both post-change CI and Gowin bitstream generation were successful. Logic decreased from **8995 (old failed synthesis)** to **6513 (new PnR)**, a reduction of **2482** mapped logic units, approximately **27.6%** relative to the old result.

## Partial STA review from operator-provided HTML-to-text excerpt

The report automatically recognized 126 MHz PLL and 25.2 MHz pixel derived clocks, and its TNS table lists 27 MHz reference too. The pixel Fmax estimate is **26.280 MHz versus the 25.200 MHz requirement**. Setup worst shown path **+1.630 ns**, from `u_game/ai_left_safe_s0/Q` to `u_game/trail_b[8]_9_s1/CE` (gameplay memory write enable). Hold worst shown **+0.550 ns**, in the SVO encoder/blue-channel buffering. The report gives zero setup/hold violating endpoints. **This is not a full timing-coverage certificate.**

### Remaining gates

1. Inspect **Recovery/Removal minimum slack** in the same `20261026_185436` HTML report. Check timing exceptions, unconstrained paths and reset/CDC coverage if present. The supplied excerpt ended before Recovery/Removal.
2. Decide SRAM-only board-test gate based on these data; frequency headroom of roughly **4.3%** is small and is a reason to keep the build unchanged while testing.
3. Only after timing review, conduct **2–3 controlled SRAM-only** operator board tests on Tang Nano 9K. **BOARD NOT RUN**.
4. Do not merge draft PR, publish binary or add browser console profile before board acceptance. **No FPGA Flash programming.**

Use **read-only native PowerShell** extraction from the original `konsol_lightcycles_rgb_nano9k_tr_content.html`; there is no committed `inspect_rs005_sta.ps1` tool in this branch.
