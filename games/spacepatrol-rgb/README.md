# KonSol RetroStation — RS-006 SPACE PATROL RGB v0.1.0

**STATUS: RTL CI SIM PASS (28 checks, run 40446452292); GOWIN FIT/STA NOT RUN; BOARD NOT RUN; NOT RELEASED.**

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
- FT2232 B COM port, 115200 8N1. The existing browser console does **not** yet have an RS-006 profile; add it only after SHA-pinned board acceptance.

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

The script validates pinned SVO source and runs Gowin CLI in a timestamped folder; it does not program the FPGA. Treat all generated .fs files as **candidate only** until exact-build resources, setup/hold/recovery/removal, clock constraints, unconstrained paths and the STA audit have been reviewed.

## Hardware gate (2–3 focused tests; never write Flash)

1. **SRAM-only** loading and stable HDMI; movable ship, 24 enemies and visible bullets.
2. FT2232 UART via PowerShell: move, fire, destroy targets, score and life loss.
3. Win/lose, restart, reset and four palettes. Confirm exact SHA-256 and document operator observations, then publish an immutable release and fourth/fifth console profile.

Use the controller (no FPGA programming):

```powershell
.\games\spacepatrol-rgb\tools\control_spacepatrol.ps1 -PortName COM10
```

Do not begin repeated RTL rewrites after 2–3 failed hardware tests; check cable, power, COM and clock/reset first.

**License:** original gameplay MIT; SimpleVOut ISC and Gowin vendor IP separate.
