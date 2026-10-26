# RS-002 — PONG RGB v1.2: board acceptance / приёмка на плате

**Protocol version:** 0.1 (2026-10-26). **Status: NOT RUN under this protocol.**
The pre-existing operator demonstration is **operator-reported BOARD PASS**, but it is not evidence that the exact three checks below have been rerun.

## Identity / Идентификация

- Game: PiKoSoL PONG RGB v1.2
- Board: **Sipeed Tang Nano 9K / Gowin GW1NR-9C only**
- Source: https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/pong-rgb
- Release: https://github.com/AIDevelopersMonster/Sipeed-FPGA/releases/tag/pikosol-pong-rgb-v1.2
- Filename: `pikosol_pong_rgb_nano9k.fs`
- Size: **2,070,601 bytes**
- SHA256: `978D9BCFF7C1EF1350F88AF2C603A00B7D3BB6325EA39019CA57CF5091639F96`
- WebUSB: https://aidevelopersmonster.github.io/Sipeed-FPGA/lab04/web-loader/
- PONG Web Serial: https://aidevelopersmonster.github.io/Sipeed-FPGA/pong-rgb/
- Other firmware (regression): `pikosol-v0.2.0` / `picorv32_lab04_hdmi_nano9k.fs` SHA256 `6862C034715DBF557C93C8F8AF8D8AA856CA8F4E62997660CEA9740F3EFDA356`.

## Preparation / Подготовка

PowerShell 7 on Windows, Chrome/Edge, Tang Nano 9K, HDMI screen, USB cable, FT2232 JTAG A driver and serial channel B (115200 8N1). Close any competing program that already holds JTAG/UART.

From local KonSol repository:

```powershell
Set-Location C:\GitHub\KonSol-RetroStation
git pull --ff-only origin main
.\tools\prepare_rs002.ps1
```

This helper downloads the **official release asset** into `acceptance-local/RS-002`, verifies its length and SHA, and writes a local JSON receipt with tests marked **NOT_RUN**. It performs **no FPGA programming**. The `acceptance-local/` directory is ignored by Git.

**Exact-build STA caveat:** the standalone post-route STA report bound to the above binary SHA is not archived in the source repo. The operator should attach the matching report if available. Do not borrow STA results from a different `.fs` hash. This documentation gap is tracked separately from the three functional board checks.

## Board tests / Три теста на плате

### RS002-T01 — verified WebUSB SRAM load and HDMI

1. In PiKoSoL WebUSB Loader choose **PONG RGB v1.2** for **Tang Nano 9K**. Obtain the release binary from GitHub Pages or select the locally downloaded exact `.fs`.
2. Verify SHA-256 **PASS**, connect **JTAG Debugger** via WebUSB (FT2232 channel A), then program **volatile SRAM only**. Never use `--flash`, `-f`, or an erase command.
3. Observe the real HDMI display: PONG playfield, score, ball and two paddles; no unexplained reset/flicker.

**PASS:** the expected hash matches, the programming engine returns code 0, and the HDMI playfield visibly runs. Save loader log and photo/video. A download success alone does **not** prove hardware load.

### RS002-T02 — live input and game mechanics

1. Open Pong control page, connect the **USB serial channel B at 115200**, focus the control panel.
2. Check **W/S** left paddle; toggle **A** (AI off) and check **I/K** right paddle. Select **5/6/7** and observe the large AI indicator **1/2/3** and differences in response. Check **1–4** palettes.
3. Observe at least two different paddle impact zones giving different ball trajectories; allow either side to reach **9**, confirm freeze/blink; press **R**, confirm 0:0 and movement resumes after play.

**PASS:** UART control, visibly varying bounce, score 9 win/freeze and restart work. Record observed keys and photo/video. If one individual observation cannot be completed, mark the test **PARTIAL**, not PASS.

### RS002-T03 — firmware switching regression

1. In the **same** WebUSB Loader, choose **PiKoSoL v0.2.0**, download its different checksum-pinned image; load **SRAM only**.
2. Confirm Pong is replaced by the PiKoSoL HDMI interface. In [PiKoSoL Web Serial Control Center](https://aidevelopersmonster.github.io/Sipeed-FPGA/lab04/web-control/) connect channel B, run `INFO` or `HELP`.
3. Optionally repeat with SD-08, using read-only `FS`/`DIR` on a prepared SD; do not invoke SD write commands.

**PASS:** successful switch back to the base firmware without Flash writes; HDMI and UART controls operate. Save loader/terminal logs. SD-08 is optional, not part of the mandatory pass condition.

## Evidence and status / Квитанция

The script generates a local receipt `acceptance-local/RS-002/RS002_RECEIPT.json`. After testing, fill in:

- `tested_at`, `board_sample`, `host_os`, `tool_versions`
- For each `tests[].status`: `PASS`, `FAIL`, `PARTIAL`, or `NOT_RUN`
- `tests[].notes` and `evidence` (paths or public URLs to logs/photos)
- `sta_report` for the **same** candidate hash, if it exists.

Do **not** commit a receipt claiming PASS without actually performing the relevant physical tests. Keep older evidence intact when rerunning. Never rewrite the original released binary.

**Failure policy:** stop after 2–3 documented tests. Diagnose cable, FT2232 drivers, 27 MHz clock/reset, HDMI monitor and Windows USB access before changing already working RTL.

## English summary

This is a reproducible three-check **operator** acceptance protocol: (T01) SHA-pinned WebUSB SRAM program + real HDMI, (T02) UART paddle/AI/collision/9-point win/reset, (T03) change to base PiKoSoL and verify HDMI/UART. The receipt starts as **NOT_RUN**. No simulated test can replace physical board evidence.
