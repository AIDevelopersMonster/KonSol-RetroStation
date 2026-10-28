# KonSol RetroStation

**Open FPGA, MCU & SBC Retro Gaming Platform**

[Русский](#русский) · [English](#english) · [Architecture](docs/ARCHITECTURE.md) · [Project inventory](docs/INVENTORY.md) · [Roadmap](docs/ROADMAP.md) · [Machine-readable catalog](catalog/README.md) · [Next games for Tang Nano 9K](docs/FPGA_9K_GAMES_NEXT.md)

**Игровая WebUSB-консоль:** [открыть на GitHub Pages](https://aidevelopersmonster.github.io/KonSol-RetroStation/console/) *(после успешного развёртывания Pages)* · [исходники и инструкции](docs/console/README.md). **Семь профилей:** PONG, BREAKOUT, K-BLOCKS, LIGHT CYCLES, SPACE PATROL, MAZE CHASE, MINI TD; SRAM only, SHA-256, Web Serial. [Каталог всех семи игр](games/README.md).

**Four-game showcase video:** https://youtube.com/shorts/slVuWt4V09M (PONG, BREAKOUT, K-BLOCKS, LIGHT CYCLES; filmed before RS-006).

**Project founded: 26 October 2026.** [Founding video — KonSol RetroStation: Project Day 1](https://youtu.be/Hjy9AaBeEGs).

## Русский

**KonSol RetroStation** — открытая исследовательская и образовательная платформа для ретроигр, собственных игровых систем и воспроизводимых аппаратно-программных экспериментов.

Три направления: **FPGA** (игра реализована в логике), **MCU** (игра исполняется микроконтроллером), **SBC** (игра или эмулятор исполняется одноплатным компьютером). **Hybrid** — возможное сочетание этих архитектур, но не обязательное требование.

Это **экосистема проектов**, а не единая прошивка, универсальная игровая ОС или заявка на полную эмуляцию старых приставок. Собственные игры и эмуляция исторических систем — разные категории.

### Что реально доступно

| Направление | Проект | Статус | Исходники / запуск |
| --- | --- | --- | --- |
| FPGA / Tang Nano 9K | **SPACE PATROL RGB v0.1.0** | OPERATOR BOARD PASS; SIM 28/28, FIT/STA positive sampled margins, exact SHA-pinned .fs published | [Исходники](games/spacepatrol-rgb/README.md) · [Приёмка](games/spacepatrol-rgb/acceptance/RS006_BOARD_2026-10-27.md) · [Консоль](docs/console/README.md) |
| FPGA / Tang Nano 9K | **LIGHT CYCLES RGB v0.1.0** | OPERATOR BOARD PASS 3/3; SIM 78/78, FIT/STA excerpts PASS; exact .fs pending release | [Исходники](games/lightcycles-rgb/README.md) · [Приёмка](games/lightcycles-rgb/acceptance/RS005_BOARD_2026-10-27.md) · [Консоль](docs/console/README.md) |
| FPGA / Tang Nano 9K | **K-BLOCKS RGB v0.1.0** | OPERATOR BOARD PASS; SIM 53/53, Gowin PnR/STA excerpts checked; exact `.fs` local, release pending | [Исходники](games/kblocks-rgb/README.md) · [Отчёт](games/kblocks-rgb/acceptance/RS004_BOARD_2026-10-26.md) · [Консоль](docs/console/README.md) |
| FPGA / Tang Nano 9K | **BREAKOUT RGB v0.1.0** | Оператор прошёл игру до победы; релиз SHA-256 подтверждён | [Исходники](https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/breakout-rgb) · [Релиз](https://github.com/AIDevelopersMonster/Sipeed-FPGA/releases/tag/konsol-breakout-rgb-v0.1.0) |
| FPGA / Tang Nano 9K | **PiKoSoL PONG RGB v1.2** | Оператор подтвердил работу на плате; опубликован проверяемый бинарник | [Проект](https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/pong-rgb) · [Релиз](https://github.com/AIDevelopersMonster/Sipeed-FPGA/releases/tag/pikosol-pong-rgb-v1.2) |
| MCU / Arduino UNO + TFT | **Arkanoid / Breakout Touch** | Исходники и тестовый план для конкретной аппаратной конфигурации | [Проект](https://github.com/AIDevelopersMonster/Arduino-UNO-Shields/tree/main/shields/MAR2406-2.4-TFT/examples/Arkanoid_Breakout_Touch) |
| MCU / Arduino UNO + TFT + SD | **Tic-Tac-Toe** | Закрытая LAB-03; тестовая сборка подтверждена | [LAB-03](https://github.com/AIDevelopersMonster/Arduino-UNO-Shields/tree/main/labs/03-UNO-MAR2406-TFT) |
| MCU / Arduino UNO / Nano | **Snake** | Несколько исходных реализаций; совместимость уточняется отдельно | [Исходники](https://github.com/AIDevelopersMonster/Snake_Game) |
| MCU / ESP8266 | **Flappy Bird** | Исходники, инструкция, видеодемонстрация; отдельная приёмка не выполнена здесь | [Исходники](https://github.com/AIDevelopersMonster/Flappy-Bird-on-ESP8266) |
| MCU / LCD Keypad Shield | **17 ретроигр** | Историческая коллекция адаптаций; права на каждый компонент проверяются отдельно | [Коллекция](https://github.com/AIDevelopersMonster/arduino-lcd-keypad-shield-games) |
| SBC | — | Пока нет зарегистрированной проверенной игровой реализации | [Архитектура](docs/ARCHITECTURE.md) |

**Статус относится к конкретной реализации и представленным доказательствам**. Публикация исходников, успешная сборка, опыт на плате и публикация бинарника — разные события. Подробнее: [аудит](docs/INVENTORY.md).

### Запуск игр на Tang Nano 9K

**BREAKOUT RGB v0.1.0:** откройте [PiKoSoL WebUSB Loader](https://aidevelopersmonster.github.io/Sipeed-FPGA/lab04/web-loader/), выберите профиль **KonSol BREAKOUT RGB**, получите `.fs` с GitHub Pages (или из [релиза](https://github.com/AIDevelopersMonster/Sipeed-FPGA/releases/tag/konsol-breakout-rgb-v0.1.0)), дождитесь проверки SHA-256 и загрузите **только в SRAM**. Для игры используется [PowerShell UART-контроллер](https://github.com/AIDevelopersMonster/Sipeed-FPGA/blob/main/games/breakout-rgb/tools/control_breakout.ps1) через COM-порт FT2232 B, 115200 8N1. Работа браузерной автоматической загрузки на физической плате ещё отдельно не проверена; использование локального Gowin Programmer уже подтверждено оператором.

### Запуск первого проекта — PONG RGB на Tang Nano 9K

1. Подключите **Sipeed Tang Nano 9K (GW1NR-9C)** по USB и HDMI. Используйте Chrome/Edge с WebUSB; в Windows необходим настроенный доступ к FT2232 JTAG-каналу A. Последовательный порт FT2232, канал B, остаётся для UART.
2. Откройте [PiKoSoL WebUSB Loader](https://aidevelopersmonster.github.io/Sipeed-FPGA/lab04/web-loader/), выберите **PONG RGB v1.2** и скачайте закреплённый файл `.fs` с GitHub Pages либо выберите локальный файл из [официального релиза](https://github.com/AIDevelopersMonster/Sipeed-FPGA/releases/tag/pikosol-pong-rgb-v1.2). Проверьте SHA-256.
3. Выберите JTAG Debugger и запрограммируйте **только SRAM**. Конфигурационная Flash не затрагивается. На HDMI должна появиться игра.
4. Откройте [Web Serial Pong Keyboard](https://aidevelopersmonster.github.io/Sipeed-FPGA/pong-rgb/), подключите UART **115200 8N1**, щёлкните по области управления. `W/S` — левый игрок, `I/K` — правый, `A` — AI, `5/6/7` — сложность, `1–4` — цвета, `R` — перезапуск.

**Опубликованный PONG v1.2:** `pikosol_pong_rgb_nano9k.fs`, 2 070 601 байт, SHA-256:

```text
978d9bcff7c1ef1350f88af2c603a00b7d3bb6325ea39019ca57cf5091639f96
```

После отключения питания SRAM-конфигурация теряется. **Нельзя использовать этот битстрим для другой модели FPGA.** Игра реализована аппаратно на Verilog без CPU PicoRV32. Отдельный итоговый STA-отчёт, однозначно связанный с этим SHA, не приложен к исходному репозиторию; уровень доказательств указан в [аудите](docs/INVENTORY.md).

### Принципы

- **Никакого дублирования кода:** PiKoSoL и остальные игры остаются в исходных репозиториях; здесь — каталог, паспорт, доказательства и ссылки.
- **Совместимость по плате:** не показывать `.fs` в качестве совместимого с другой FPGA, пока не подтверждены её устройство, распиновка и сборка.
- **CLI-first:** PowerShell 7, Git/GitHub CLI, сборка и тесты со скриптов.
- **Без бесконечной отладки:** 2–3 документированных испытания платы, затем анализ аппаратного тракта или остановка.
- **Юридическая дисциплина:** нельзя считать внешний код, ROM, игровые ресурсы и IP свободными от ограничений только потому, что они находятся на GitHub.

Каталог: [платформы](catalog/platforms.json) · [игры](catalog/games.json). Проверка каталога:

```powershell
git clone https://github.com/AIDevelopersMonster/KonSol-RetroStation.git
Set-Location .\KonSol-RetroStation
.\tools\check_catalog.ps1
```

**Первые три работы:** [RS-001 / RS-002 / RS-003](docs/ROADMAP.md). **RS-003 BREAKOUT v0.1.0 уже реализован, испытан оператором и опубликован в prerelease.** Следующие кандидаты для Tang Nano 9K и критерии выбора: [RS-004+](docs/FPGA_9K_GAMES_NEXT.md).

## English

**KonSol RetroStation** is an open educational and research project covering **FPGA**, **MCU** and **SBC** retro games, hardware game engines, and reproducible implementations.

It is **not** a universal firmware image or a claim that a historical console emulator already works. Individual projects retain their own sources, authorship, licenses, hardware targets and evidence. The central repository is a **catalog and project governance layer**, not a vendor-code archive.

### Two operator-board-tested FPGA titles

[BREAKOUT RGB v0.1.0](https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/breakout-rgb) is the second independent native Verilog game, with 32 bricks, three lives, HDMI and a PowerShell UART controller. The operator completed a game to victory on a physical Tang Nano 9K; a [SHA-256-pinned public prerelease](https://github.com/AIDevelopersMonster/Sipeed-FPGA/releases/tag/konsol-breakout-rgb-v0.1.0) is available. Its browser programming profile has not received a separate complete end-to-end hardware acceptance.

[PiKoSoL PONG RGB v1.2](https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/pong-rgb) is an independently implemented Verilog HDMI game for the **Sipeed Tang Nano 9K**. It has operator-reported physical-board success and a [public SHA-256-pinned release](https://github.com/AIDevelopersMonster/Sipeed-FPGA/releases/tag/pikosol-pong-rgb-v1.2).

**Quick start:** connect Tang Nano 9K + HDMI → open [PiKoSoL WebUSB Loader](https://aidevelopersmonster.github.io/Sipeed-FPGA/lab04/web-loader/) → select PONG RGB v1.2 → download and verify the bitstream → program **volatile SRAM only** → open the [Web Serial Pong controller](https://aidevelopersmonster.github.io/Sipeed-FPGA/pong-rgb/) at **115200 8N1**. Keyboard: `W/S`, `I/K`, `A`, `5/6/7`, `1–4`, `R`.

**Existing MCU references:** [Arduino UNO Breakout Touch](https://github.com/AIDevelopersMonster/Arduino-UNO-Shields/tree/main/shields/MAR2406-2.4-TFT/examples/Arkanoid_Breakout_Touch), [Arduino UNO Tic-Tac-Toe](https://github.com/AIDevelopersMonster/Arduino-UNO-Shields/tree/main/labs/03-UNO-MAR2406-TFT), [Snake](https://github.com/AIDevelopersMonster/Snake_Game), [ESP8266 Flappy Bird](https://github.com/AIDevelopersMonster/Flappy-Bird-on-ESP8266), and [LCD Keypad Shield games](https://github.com/AIDevelopersMonster/arduino-lcd-keypad-shield-games). These are references, not copied or uniformly hardware-certified releases.

**SBC:** planned architecture track; no SBC gaming image is released here yet.

### Development rules

- Keep source-of-truth code in its originating repository; avoid duplicate forks and binaries.
- Differentiate `SOURCE`, `BUILD PASS`, `BOARD PASS`, and `RELEASED`; a release is not a hardware certification.
- Bind any FPGA binary to its **exact target board**, release URL and SHA-256.
- Preserve third-party notices, licenses and ROM restrictions.
- Prefer reproducible PowerShell/CLI workflows; run only 2–3 focused board tests before deciding whether a new hardware investigation is worthwhile.

Start with [Architecture](docs/ARCHITECTURE.md), [Inventory](docs/INVENTORY.md), [Roadmap](docs/ROADMAP.md), [next Tang Nano 9K game candidates](docs/FPGA_9K_GAMES_NEXT.md), and the [catalog](catalog/README.md).

**Vision:** from one working game and one board to a carefully documented FPGA, MCU & SBC retro-gaming ecosystem.
