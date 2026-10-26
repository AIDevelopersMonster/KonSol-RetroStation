# Architecture / Архитектура — KonSol RetroStation v0.1

## RU: границы проекта

KonSol RetroStation — **каталог совместимых игровых реализаций и технических доказательств**. Он не становится главным исходным репозиторием всех игр, общей прошивкой или новым универсальным загрузчиком.

```text
KonSol RetroStation (catalog / architecture / evidence)
  |-- FPGA: PiKoSoL / Sipeed-FPGA
  |     |-- verified target: Tang Nano 9K
  |     |-- standalone Verilog game .fs: PONG RGB v1.2
  |     |-- browser: existing WebUSB SRAM loader + Web Serial
  |     +-- next candidate: native Breakout
  |-- MCU: existing Arduino / ESP8266 game repositories
  |     +-- independent builds and hardware-specific input/display drivers
  |-- SBC: future track (no board-verified game in this catalog)
  +-- Hybrid: optional integrations, only if justified
```

### Источник истины и отсутствие дублирования

1. Исходники игр, сборочные скрипты, vendor/IP-уведомления, релизы и инструкции остаются в **исходных репозиториях**.
2. Этот репозиторий содержит только документацию, ссылки, метаданные совместимости и скрипты проверки **самого каталога**.
3. Не копировать чужие исходники, ROM, бинарники или сторонние EDA/IP без отдельного разбора лицензии.
4. Не создавать в RetroStation дубликат WebUSB-загрузчика PiKoSoL. Изменения программирования ведутся в Sipeed-FPGA, а RetroStation ссылается на действующую страницу.

### Уровни доказательств

- **DISCOVERED:** обнаружен репозиторий или исходный проект; пригодность и сборка не проверены.
- **SOURCE DOCUMENTED:** есть исходники и объяснение запуска, но нет нашего полного результата сборки.
- **BUILD PASS:** сборка на конкретных инструментах подтверждена и задокументирована.
- **OPERATOR BOARD PASS:** оператор подтвердил наблюдаемую работу на физическом стенде; это не независимая сертификация.
- **RELEASED:** доступен опубликованный файл; статус публикации не подразумевает ни BUILD PASS, ни BOARD PASS.
- **CANDIDATE:** ещё не принятая концепция, которую нельзя показывать как работающий выпуск.

Несколько признаков могут выполняться одновременно. Реестр имеет поле `evidence_level` и отдельное `distribution.status`, чтобы не смешивать испытание с публикацией.

### Board → Firmware → Requirements → Programming

Для FPGA запись в реестр содержит точную модель, устройство, интерфейсы, URL релиза, контрольную сумму и способ программирования. Пока загрузчик PiKoSoL работает **для Tang Nano 9K**, а назначение файла `.fs` на другие FPGA запрещено.

Загрузка в FPGA **SRAM** полностью заменяет аппаратную конфигурацию: PONG не исполняется внутри PiKoSoL v0.2.0 / PicoRV32. Никакой записи во Flash в рамках RetroStation v0.1.

Для MCU и SBC позже появятся собственные механизмы установки. Нельзя выдавать FPGA WebUSB-программатор за загрузчик MCU/SBC. Идентификация платы по WebUSB без надёжного аппаратного механизма не заявляется.

### Видеовывод, ввод и память

Никакой единой межплатформенной графической ABI на v0.1 не вводится. HDMI в FPGA, TFT в MCU и оконный/DRM-видеовывод на SBC реализуются по правилам соответствующей платформы. Разумно унифицировать только **паспорт игры** (display/input/audio/memory), не исходный драйвер.

### Юридические границы

KonSol не присваивает лицензии внешних репозиториев. PiKoSoL original RTL: MIT; SimpleVOut: ISC, Clifford Wolf; Gowin IP/EDA: условия производителя. Для Flappy Bird исходный репозиторий указывает GPL-3.0. Для старых Arduino-адаптаций и отсутствующих LICENSE необходимо отдельное изучение авторских прав и upstream-уведомлений **до** перепубликации. ROM-файлы коммерческих игр нельзя автоматически распространять вместе с FPGA-ядрами. Собственная лицензия материалов **этого** репозитория требует явного решения владельца; отсутствие LICENSE не трактовать как разрешение на копирование.

## EN: architectural contract

KonSol RetroStation is a **linked, evidence-aware project catalog**, not a universal bitstream or an alternate source mirror.

- Keep source, build scripts, upstream licenses, and binary releases in their original repositories.
- Register the precise board and requirements of each game.
- Treat source presence, compilation, physical-board evidence and release publication as separate claims.
- For Tang Nano 9K, only the existing PiKoSoL WebUSB loader programs `.fs` to **volatile SRAM**; a selected image replaces the current FPGA configuration.
- MCU and SBC programming/deployment are independent workflows.
- Plan hybrid FPGA+MCU+SBC solutions only when the integration has a concrete, measurable benefit.
- Do not port or redistribute historical game ROMs and third-party cores without a license review.

First implementation track: **FPGA native arcade**, with Pong as an operator-validated reference, followed by a small independent Breakout candidate.
