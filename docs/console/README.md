# KonSol RetroStation — Game Console / WebUSB programmer

**Project:** [KonSol-RetroStation](https://github.com/AIDevelopersMonster/KonSol-RetroStation). **Board:** Sipeed Tang Nano 9K / GW1NR-9C. **Hardware actions:** WebUSB JTAG A → *volatile SRAM only*, Web Serial UART B → game controls. **No Flash operations.**

## Public GitHub Pages URL (after successful deployment)

https://aidevelopersmonster.github.io/KonSol-RetroStation/console/

This URL is the **target of the Pages workflow**, not proof that Pages has been enabled, deployed or physically tested. Repository Settings → Pages → Build and deployment → Source **GitHub Actions** may be required before the first site can go live.

## Games and distribution

| Game | Firmware owner | SHA-256 source | Official Pages download |
| --- | --- | --- | --- |
| Pong RGB v1.2 | Sipeed-FPGA release | `978d9bcf...f96` | Yes, after site build |
| Breakout RGB v0.1.0 | Sipeed-FPGA release | `4cf80dbd...789` | Yes, after site build |
| K-Blocks RGB v0.1.0 | KonSol-RetroStation release | `f842b196...c4e` | **Local `.fs` first**; automatic download only after exact binary release upload and automatic Pages rebuild |

The browser uses `console/profiles.json` (pinned SHA and file size) and generated `console/firmware/manifest.json` (present/verified-at-deploy asset availability). A profile is displayed as remote ready only when the binary was successfully obtained and SHA-256 checked by the Pages workflow. The browser independently hashes the firmware again before programming. An arbitrary local `.fs` that does not match the selected profile's SHA is **rejected**.

**Important:** creating the GitHub Pages source files does not imply a WebUSB hardware pass. Each browser flow must be observed on a real Tang Nano 9K separately.

## Launch flow

1. On Windows, use Chrome or Edge over HTTPS. Install WinUSB on FT2232 interface A (`MI_00`) if necessary, leave interface B (`MI_01`) as a COM port. Do not change the tested driver setup if it already works.
2. Select Pong, Breakout or K-Blocks. Use **Get from GitHub** when available; otherwise select a local exact-bitstream `.fs`.
3. Confirm `SHA-256 PASS` and select **JTAG Debugger** (FT2232 `0403:6010`). Click **Program SRAM**. This is an explicit user action; the page never writes Flash.
4. Check HDMI. If desired, connect **Web Serial** to the FT2232 COM port, click gamepad area and play with the keyboard. Pong: W/S and I/K; Breakout: arrows/A/D; K-Blocks: arrows plus P/R.
5. When switching games, repeat the SRAM load; the games are mutually exclusive FPGA images.

## Publishing K-Blocks firmware from the tested Windows PC

After RS-004 source is merged to `main`, use the local script from **KonSol-RetroStation**. It has exact size/hash gates and is a dry run by default:

```powershell
Set-Location C:\GitHub\KonSol-RetroStation
git switch main
git pull --ff-only
$FS = 'C:\GitHub\KonSol-RetroStation\games\kblocks-rgb\build\20261026_125847\work\impl\pnr\konsol_kblocks_rgb_nano9k.fs'
.\games\kblocks-rgb\publish_release.ps1 -Bitstream $FS
# Only when source/licence and checksum accepted:
.\games\kblocks-rgb\publish_release.ps1 -Bitstream $FS -Publish
```

The workflow watches for the `konsol-kblocks-rgb-v0.1.0` release and stages the exact checked `.fs` in a same-origin GitHub Pages artifact. The script verifies the GitHub asset by downloading it again. **Neither script nor workflow programs any FPGA device.**

## Reproducible GitHub Pages build

[Workflow](../../.github/workflows/publish-retrostation-console.yml) performs:

- Static tests for JS, profile content, SHA-256 and no Flash commands.
- Downloads `@yowasp/openfpgaloader@1.1.1-182.269` from npm; checks the `bundle.js`/`openFPGALoader.wasm` SHA-256 against the known working PiKoSoL files. Other runtime assets remain together in `console/vendor/`.
- Downloads MIT licensed `coi-serviceworker v0.1.7` from **an exact pinned Sipeed-FPGA commit**, verifies its Git blob, hosts it under the console's own origin to provide WASM COOP/COEP on GitHub Pages.
- Downloads publicly released Pong and Breakout `.fs`, checks exact file length and SHA-256; adds K-Blocks **only when its official release is available**.
- Generates a manifest from the exact checked assets, uploads a GitHub Pages artifact; never pushes vendor binaries into the source repository.

When Pages is not activated, select `Settings → Pages → Build and deployment → GitHub Actions`. The repository must allow Actions/Pages deployments; a failure means the page is **not yet live**.

## Licensing and scope

- Original console HTML/JS/CSS and CLI scripts: MIT where indicated; preserve repo notices.
- WebAssembly runtime: YoWASP `@yowasp/openfpgaloader` ISC; bundled by a pinned build step, with package metadata in npm and original source notices.
- COI service worker: Guido Zuidhof and contributors MIT.
- OpenFPGALoader itself: original source/derivatives carry their own license terms.
- FPGA game code and assets remain under their original repositories; Gowin vendor terms still apply.

No unauthorized game ROM, system firmware for another board, external RAM controller, multi-boot Flash image or claimed physical certification is included here.
