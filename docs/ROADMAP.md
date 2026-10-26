# Roadmap v0.2 / Первые работы и план продолжения

**Rule:** each milestone has a concrete output, acceptance criteria and a stop condition. Dates are not delivery promises.

## Фактический статус на 26.10.2026 / Status snapshot

| Этап | Итог | Остаточный контроль |
| --- | --- | --- |
| RS-001 Foundation | Документация и машинный каталог опубликованы в `main` | Независимый Windows PowerShell прогон валидатора не заявлен в этом аудите |
| RS-002 PONG RGB v1.2 | OPERATOR BOARD PASS; опубликован prerelease с SHA-256 | Полный сквозной браузерный протокол и STA, привязанный к этому же SHA, ещё не архивированы |
| RS-003 BREAKOUT RGB v0.1.0 | **OPERATOR BOARD PASS, выигранная партия, исходники в main, prerelease опубликован** | Полный независимый STA и браузерный end-to-end BOARD PASS не заявлены |

**Документы:** [Квитанция RS-003](acceptance/RS003_BREAKOUT_BOARD_2026-10-26.md) · [Предложения новых игр RS-004+](FPGA_9K_GAMES_NEXT.md). Первоначальные критерии ниже сохраняются как историческая постановка задачи, а не список ещё не выполненных работ.

## RU: первые три самостоятельные работы

### RS-001 — Foundation / каталог, архитектура и реестр

**Цель:** превратить новый репозиторий KonSol RetroStation в понятную исходную точку, не клонируя остальные проекты.

**Артефакты:** двуязычный README; `docs/ARCHITECTURE.md`; `docs/INVENTORY.md`; `catalog/platforms.json`; `catalog/games.json`; проверка каталога из PowerShell.

**Приёмка:** GitHub `main` содержит документы; в реестре ссылки на реально существующие проекты; `.\tools\check_catalog.ps1` завершается строкой `KONSOL_CATALOG_PASS`; ни один исходный RTL/скетч/ROM/.fs не продублирован.

**Статус (26.10.2026):** документы, каталог и валидатор размещены в `main`. Проверка из текущего удалённого аудита не заменяет локальный запуск PowerShell на Windows.

### RS-002 — PONG v1.2 как эталонный релиз RetroStation

**Цель:** обеспечить воспроизводимый путь от каталога до реального FPGA-игрового сеанса.

**Исходные активы:** [Sipeed-FPGA/games/pong-rgb](https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/pong-rgb), [битстрим v1.2](https://github.com/AIDevelopersMonster/Sipeed-FPGA/releases/tag/pikosol-pong-rgb-v1.2), [WebUSB Loader](https://aidevelopersmonster.github.io/Sipeed-FPGA/lab04/web-loader/), [Web Serial](https://aidevelopersmonster.github.io/Sipeed-FPGA/pong-rgb/).

**Приёмка — 3 коротких теста на плате:**

1. **LOAD / IDENTITY:** выбрать Tang Nano 9K / Pong, получить `.fs` с GitHub, сравнить SHA-256 с опубликованным; JTAG загрузка только в SRAM, HDMI показывает игру.
2. **CONTROL / GAME:** Web Serial 115200; `W/S`, `I/K`, `A`, `5/6/7`, `R`; проверить изменение направления мяча от места удара и завершение партии при 9 очках.
3. **REGRESSION:** повторно выбрать базовый PiKoSoL v0.2.0 либо SD-08 и проверить, что другой профиль по-прежнему скачивается/выбирается; **не использовать Flash**.

**Требования по завершению:** сохранить логи, модель платы, дату, SHA, результат тестов, при возможности привязанный к SHA post-route STA. До этого в каталоге допустим только `operator_board_pass` + `released`, без заявления полной независимой аттестации.

**Остановка:** если 2–3 проверки не дают успеха, фиксировать ошибки и переходить к проверке кабеля/драйверов/HDMI/JTAG; не переписывать рабочий Pong без найденного дефекта.

### RS-003 — Native FPGA Breakout / следующий самостоятельный игровой модуль

**Цель:** создать оригинальный Verilog Breakout для Tang Nano 9K и сравнить архитектуру с существующим [MCU Breakout Touch](https://github.com/AIDevelopersMonster/Arduino-UNO-Shields/tree/main/shields/MAR2406-2.4-TFT/examples/Arkanoid_Breakout_Touch).

**Размещать код:** `Sipeed-FPGA/games/breakout-rgb/`, **не** в корне KonSol RetroStation; использовать проверенную инфраструктуру HDMI, UART и clock/reset через source-level reuse, не копировать vendor-код в RetroStation.

**MVP:** 640×480 HDMI; мяч, платформа, поле кирпичей в регистрах (без framebuffer/SD); счёт, три жизни, победа/поражение и restart; управление Web Serial. Отражение от ракетки зависит от точки удара. Новая игра должна быть независима от логики Pong там, где механика отличается.

**Приёмка:** Verilog testbench для столкновений, счёта/жизней и перезапуска; Gowin synth/PnR; zero setup/hold violation endpoints и положительные slacks для **точного** кандидата; 2–3 физических теста (управление + рикошет, разрушение кирпичей + счёт, конец партии + restart). Только после этого GitHub Release, SHA-256 и опциональный четвёртый профиль 9K WebUSB Loader.

**Срок/стоп:** бюджет bring-up **1–2 дня**; если за это время не получен внятный прогресс после 2–3 тестов, остановить, документировать и вернуться к аппаратной/временной диагностике. Никакого ремонта дешёвой платы ради этой задачи.

**Образовательный итог:** одна игровая концепция на MCU и FPGA, с объяснением различий между последовательным кодом MCU и параллельной цифровой логикой.

### После RS-003 — выбор RS-004+

RS-003 завершён как аппаратная игра с официальным prerelease, но профиль WebUSB остаётся без отдельной сквозной аппаратной приёмки. Не переносить это ограничение на физическую игру, уже подтверждённую оператором.

Основной кандидат — **K-BLOCKS RGB**, оригинальная игра с падающими фигурами (10×20 клеток). Альтернатива быстрого учебного результата — **LIGHT CYCLES RGB** (две световые трассы). Другие варианты, критерии и риски: [FPGA_9K_GAMES_NEXT.md](FPGA_9K_GAMES_NEXT.md).

**Не создавать новую долгосрочную ветку или отдельный репозиторий до утверждения конкретного RS-004.** Готовые PONG и BREAKOUT не переписывать; HDMI/UART/средства загрузки переиспользовать. Нет оснований уже сейчас объявлять завершённой эмуляцию Atari/NES или SBC-направление.

## EN: first three milestones

| ID | Deliverable | Acceptance |
| --- | --- | --- |
| **RS-001 Foundation** | Bilingual README, catalog, architecture, verified references and local PowerShell validator | Documentation on `main`; validator PASS; no duplicated game source, ROMs or binaries |
| **RS-002 Reference PONG** | Reproducible browser-to-board demo bound to a public release SHA | 3 documented tests: SRAM upload/HDMI, UART game controls and 9-point outcome, previous-profile regression |
| **RS-003 FPGA Breakout** | A small independently authored HDL game in **Sipeed-FPGA**, linked from KonSol | RTL tests, exact-build STA, 2–3 board checks and license-cleared release; 1–2 day stop criterion |

As of 26 October 2026, RS-003 has **operator-confirmed physical victory and a published binary prerelease**, while the WebUSB profile itself remains a separate acceptance item. RS-002 is also operator-board-tested and released, with incomplete exact-hash STA/browser regression evidence. [RS-004+ candidates](FPGA_9K_GAMES_NEXT.md). No emulator ROM redistribution. No SPI Flash programming.
