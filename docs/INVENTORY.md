# Technical inventory / Техническая инвентаризация

**Snapshot:** 2026-10-26. Live GitHub repositories inspected. This is a **source and publication audit**, not a new bench test.

## RU: что подтверждено

| Проект | Конкретный источник | Наблюдаемые доказательства | Ограничение |
| --- | --- | --- | --- |
| **KonSol RetroStation** | [Репозиторий](https://github.com/AIDevelopersMonster/KonSol-RetroStation) | Создан публичный репозиторий; v0.1 оформляет структуру и каталог | Новых игр здесь нет; исходный README был единственным файлом |
| **PiKoSoL PONG RGB v1.2** | [RTL и сборка](https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/pong-rgb) · [GitHub Release](https://github.com/AIDevelopersMonster/Sipeed-FPGA/releases/tag/pikosol-pong-rgb-v1.2) | Оператор подтвердил Pong на реальном Tang Nano 9K 26.10.2026; публичный `.fs` имеет проверяемый SHA-256 | Отдельный post-route STA-отчёт, связанный именно с опубликованным SHA, не архивирован в репозитории |
| **WebUSB / Web Serial** | [Загрузчик](https://aidevelopersmonster.github.io/Sipeed-FPGA/lab04/web-loader/) · [Управление](https://aidevelopersmonster.github.io/Sipeed-FPGA/pong-rgb/) | Функционирующий существующий маршрут для Tang Nano 9K: JTAG A / UART B, SRAM | Не поддерживает автоматическую идентификацию произвольных плат |
| **Arduino UNO + TFT LAB-03** | [LAB-03](https://github.com/AIDevelopersMonster/Arduino-UNO-Shields/tree/main/labs/03-UNO-MAR2406-TFT) | Завершена лаборатория с тестами дисплея, touch и SD; Tic-Tac-Toe в TEST-08 с BUILD PASS | Не объявлять каждый эскиз отдельным физическим BOARD PASS |
| **Breakout Touch** | [Исходники и checklist](https://github.com/AIDevelopersMonster/Arduino-UNO-Shields/tree/main/shields/MAR2406-2.4-TFT/examples/Arkanoid_Breakout_Touch) | Своя реализация для UNO, MAR2406, ILI9341 320×240, resistive touch; описан тестовый сценарий | Отдельной квитанции приёмки именно Breakout в проверенных материалах нет |
| **Tic-Tac-Toe vs Arduino** | [Пример](https://github.com/AIDevelopersMonster/Arduino-UNO-Shields/tree/main/shields/MAR2406-2.4-TFT/examples/TicTacToe_vs_Arduino) | Исходники для ILI9341, сенсор, игрок против Arduino | Отличать от итоговой LAB-03 Tic-Tac-Toe с историей на SD |
| **Snake_Game** | [Репозиторий](https://github.com/AIDevelopersMonster/Snake_Game) | Несколько вариантов Arduino UNO/Nano и документация | Общий уровень приёмки всех вариантов неизвестен |
| **Flappy Bird ESP8266** | [Репозиторий](https://github.com/AIDevelopersMonster/Flappy-Bird-on-ESP8266) · [Видео](https://youtu.be/M-zgmhmOkPY) | Исходник, SSD1306 128×64, кнопка, динамик и демонстрация | Лицензия GPL-3.0; повторная приёмка в RetroStation не выполнялась |
| **LCD Keypad Shield games** | [Коллекция](https://github.com/AIDevelopersMonster/arduino-lcd-keypad-shield-games) | 17 игр, исторические видео автора коллекции, ссылки на первоначальных авторов | Сборник адаптаций; лицензии отдельных игр необходимо разбирать индивидуально |
| **SBC** | — | Не найдено конкретной игры на SBC, принятой в данном каталоге | Направление, а не готовая платформа |

### Точный опубликованный PONG

- Board: `Sipeed Tang Nano 9K` / Gowin `GW1NR-9C`.
- Game: standalone Verilog hardware logic (not PicoRV32 software).
- HDMI: `640x480`; input: FT2232 UART channel B, `115200 8N1` via browser.
- Filename: `pikosol_pong_rgb_nano9k.fs`.
- Release file size: **2,070,601 bytes**.
- SHA-256: `978d9bcff7c1ef1350f88af2c603a00b7d3bb6325ea39019ca57cf5091639f96`.
- Release distribution: public **prerelease**. This does not constitute formal hardware certification.
- Versioned source: [games/pong-rgb](https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/pong-rgb).
- Licenses: original game MIT, external SimpleVOut ISC, Gowin vendor dependencies under their separate terms.

**Documentation caveat:** the PiKoSoL source README was checked in a state where it still said that the Pong binary was local/unpublished. The **live GitHub Release asset** and the published Pages checksum manifest show that it was subsequently published. For binary availability, use the release/manifest rather than outdated prose.

### Не переносить автоматически

- Собственные уровни BOARD PASS из PiKoSoL на другую сборку FPGA, изменение pinout или новую плату.
- Статус LAB-03 на каждую независимую игру для UNO.
- Исходники внешних старых игровых приставок и защищённые ROM в этот репозиторий.
- Список поддерживаемых плат с MCU/SBC на WebUSB-загрузчик, который рассчитан на Tang Nano 9K.

## EN: findings

The first release candidate of KonSol RetroStation is **a registry, not a game binary**. PiKoSoL PONG v1.2 is the existing board-operated FPGA anchor and the only game binary linked from the catalog. Arduino UNO TFT Breakout and Tic-Tac-Toe, Snake, ESP8266 Flappy Bird and historical LCD Keypad Shield games are documented MCU references with differing levels of evidence. No SBC game is claimed as released.

The exact Pong release file and its SHA-256 are recorded above and in [catalog/games.json](../catalog/games.json). An operator's successful visual hardware test is reported; no archived STA report is tied to that binary hash. Original code and distribution rights stay with the source projects.
