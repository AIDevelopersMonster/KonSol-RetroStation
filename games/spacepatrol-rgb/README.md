# KonSol RetroStation — RS-006 SPACE PATROL RGB v0.1.0

**STATUS: SIM PASS 28/28 · Gowin FIT PASS 2437/8640 logic · positive sampled STA · OPERATOR BOARD PASS · exact binary release pending.**

Original native-Verilog space shooter for **Sipeed Tang Nano 9K (GW1NR-9C)**, HDMI 640x480, FT2232 UART B at 115200 8N1. Reuses the proven RS-005/LAB-04 clock, SimpleVOut pipeline, Gowin IP, pinout and programming infrastructure, without modifying any existing games.

## Gameplay MVP

- **24 aliens**, a 6 x 4 formation; each alien has its own active state bit.
- Player moves left/right in a bounded area; **two player bullets**, one hostile bullet.
- Procedural alien/ship pixel shapes; **no external ROM, framebuffer, SD or CPU**.
- Bullet/alien collision, score, up to three lives, WIN/LOSS and full reset.
- Four palettes, blinking start and end banners (no font or third-party artwork).
- No sound, user levels or nonvolatile high scores in MVP.

## Controls

- **A/D** or **Left/Right**: move (key-down/key-up semantics).
- **F** or **Space**: fire and hold to repeat.
- **P**: start/restart; **R**: reset; **1–4**: palettes; **Q/Esc**: exit host controller.
- FT2232 B COM port, 115200 8N1. Browser console profile is planned after source merge; it will require the exact SHA-256-pinned binary.

## Local simulation (PowerShell 7)

```powershell
Set-Location C:\GitHub\KonSol-RetroStation
git switch feature/rs006-arcade
git pull --ff-only
.\games\spacepatrol-rgb\test.ps1
```

The testbench checks reset/start, source backpressure, movement, projectile timing, hit/score, remaining-life count, enemy fire, WIN/LOSS, restart and RGB handshake. A testbench is not hardware acceptance.

## Isolated Gowin build (only after SIM PASS)

```powershell
.\games\spacepatrol-rgb\build.ps1 -SipeedFpgaRoot C:\GitHub\Sipeed-FPGA
```

The script validates pinned SVO source and runs Gowin CLI in a timestamped folder; it does not program the FPGA. The tested candidate is `build/20261027_070050/work/impl/pnr/konsol_spacepatrol_rgb_nano9k.fs`, SHA-256 `71005039F565AAA6C8530341B1A1758A29C6582F577E75F2DBD1FBC0ECF0A4FD`. [Gowin receipt](acceptance/RS006_GOWIN_BUILD_2026-10-27.md); [operator board receipt](acceptance/RS006_BOARD_2026-10-27.md). Do not claim exhaustive STA/CDC certification.

## Hardware gate (2–3 focused tests; never write Flash)

1. **SRAM-only** loading and stable HDMI; movable ship, 24 enemies and visible bullets.
2. FT2232 UART via PowerShell: move, fire, destroy targets, score and life loss.
3. Win/lose, restart, reset and four palettes. The operator reports gameplay working. Publish the immutable exact-hash candidate as a release, then activate fifth console profile.

Use the controller (no FPGA programming):

```powershell
.\games\spacepatrol-rgb\tools\control_spacepatrol.ps1 -PortName COM10
```

Do not begin repeated RTL rewrites after 2–3 failed hardware tests; check cable, power, COM and clock/reset first.

**License:** original gameplay MIT; SimpleVOut ISC and Gowin vendor IP separate.
