# RS-003 — BREAKOUT RGB v0.1.0 | Operator board acceptance

**Date:** 26 October 2026. **Board:** Sipeed Tang Nano 9K / GW1NR-9C. **Status:** OPERATOR BOARD PASS + public prerelease. **Not** independent third-party certification.

## Source, build, release

- [Standalone Verilog game, build, tests and UART controller](https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/breakout-rgb), merged from [PR #26](https://github.com/AIDevelopersMonster/Sipeed-FPGA/pull/26) on 26 October 2026.
- [Operator hardware acceptance](https://github.com/AIDevelopersMonster/Sipeed-FPGA/blob/main/games/breakout-rgb/acceptance/RS003_BOARD_2026-10-26.md), [Gowin/PnR/STA receipt](https://github.com/AIDevelopersMonster/Sipeed-FPGA/blob/main/games/breakout-rgb/acceptance/RS003_STA_2026-10-26.md).
- [Public prerelease: konsol-breakout-rgb-v0.1.0](https://github.com/AIDevelopersMonster/Sipeed-FPGA/releases/tag/konsol-breakout-rgb-v0.1.0), timestamp 2026-10-26 07:33 UTC.
- File: `pikosol_breakout_rgb_nano9k.fs` (2,070,601 bytes), **SHA-256** `4cf80dbd008b0d41d4316bf63db952190c03940a4ffb1ffc00cab09210ae8789`. Release metadata hash equals the Gowin candidate hash in the operator receipt.
- Program **FPGA SRAM only**. Do not use configuration Flash.

## Actual hardware result

The operator reports loading the FPGA, seeing live HDMI graphics, controlling the paddle by Windows PowerShell via FT2232 channel B / 115200 8N1, and completing the game to **WIN**. The game has 8×4=32 bricks, three lives, four palettes and READY/PLAY/WON/LOST states. Original gameplay is Verilog without PicoRV32, ROM, OS or framebuffer.

- Icarus smoke: **PASS according to operator receipt**, including reset, launch, palette, paddle, brick, life and restart checks.
- Gowin V1.9.9 Beta-4 Education: **BUILD/PnR PASS according to operator receipt**.
- Logic 1612/8640 (19%); registers 510, report denominator 6693 (8%); BSRAM 0.
- Reported 0 setup and hold violations in the clock summaries; the **sampled minima among 25 paths each** are Setup +6.035 ns, Hold +0.550 ns, Recovery +0.232 ns, Removal +0.870 ns. This does **not** certify every path or timing exception.
- The SHA-256 published in the prerelease matches the candidate listed in the timing receipt. No independent readback of configuration from the physical FPGA was provided.

## Separate remaining verification

The **Breakout WebUSB profile** has been published and includes official SHA-256 validation. Its exact-profile **GitHub Pages → WebUSB → SRAM → HDMI** physical regression is not separately claimed as BOARD PASS. This does **not** reduce the already reported game-level operator BOARD PASS using local programming.

## English / Русский

**EN:** Second independent Tang Nano 9K hardware game. Operator successfully played to victory; exact candidate hash is matched by the published prerelease. Remaining gap: independent full STA archive and separate WebUSB hardware acceptance.

**RU:** Вторая самостоятельная аппаратная игра. Оператор прошёл её до победы на Tang Nano 9K; хеш кандидата совпадает с опубликованным prerelease. Отдельная аппаратная приёмка профиля WebUSB и полное независимое STA-покрытие не заявляются.
