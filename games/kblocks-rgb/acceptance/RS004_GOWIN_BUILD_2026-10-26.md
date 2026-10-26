# RS-004 — Gowin build candidate / 26 October 2026

**Evidence class:** OPERATOR BUILD OUTPUT, not verified timing acceptance or physical board acceptance.

## Build identity

- Project: KonSol RetroStation — RS-004 K-BLOCKS RGB v0.1.0.
- Target: **Sipeed Tang Nano 9K / GW1NR-9C** (from versioned Gowin build script).
- Local repository: `C:\GitHub\KonSol-RetroStation`; branch `feature/rs004-kblocks-rgb`.
- Script: `games/kblocks-rgb/build.ps1 -SipeedFpgaRoot C:\GitHub\Sipeed-FPGA`.
- Reused Sipeed-FPGA source checkout commit reported by the script: `22c80c18efc3b4bc769de1bf3f18ad8cdf4585b7`. Pinned SVO dependency was checked by the script.
- Local build directory: `games/kblocks-rgb/build/20261026_125847/work`.
- Candidate: `impl/pnr/konsol_kblocks_rgb_nano9k.fs`.
- Candidate SHA-256 (reported by operator): `F842B196CB4A56E0C18DEF1C471CBDDC82F59F0B552A27F553FDFF9692BBDC4E`.
- Bitstream size: **not yet reported**.
- Git identity of the exact KonSol source snapshot: **not independently recorded in the build output**. A later branch HEAD must not be retroactively treated as the build identity.
- The operator reported successful completion of Gowin `run all` with a generated `.fs`, so the **build/generation step completed**. This is not by itself evidence of positive timing margins.

## Independent earlier acceptance

- Icarus on GitHub Actions and Windows: `RS004_KBLOCKS_TB_PASS checks=53`, `RS004_TB_EXIT_0`.
- [Simulation receipt](RS004_SIM_2026-10-26.md).

## Pending — must NOT be marked PASS from this log

1. Examine `impl/pnr/konsol_kblocks_rgb_nano9k.rpt.txt` for Logic/LUT/FF/BSRAM/PLL utilization and PnR warnings.
2. Examine `impl/pnr/konsol_kblocks_rgb_nano9k_tr_content.html` (or equivalent `.tr`) for all clock domains (input 27 MHz, derived pixel 25.2 MHz and serializer 126 MHz), setup/hold violations, recovery/removal, exceptions, unconstrained paths, generated clocks and minimum pulse widths when available. The published SDC only declares the 27 MHz input clock; **review whether generated clocks are recognized automatically**.
3. Rehash the exact candidate before later SRAM programming and preserve the PnR/STA report alongside the SHA.
4. Board tests (HDMI, keyboard + cleared row, top-out/restart) **NOT RUN**.

**Release gate:** SIM PASS does not imply FIT/STA PASS; no GitHub firmware asset, no browser-loader profile, and **no Flash programming**.
