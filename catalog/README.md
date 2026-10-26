# Catalog / Каталог KonSol RetroStation v0.1

**Machine-readable files:** [platforms.json](platforms.json) and [games.json](games.json).

## RU

Каталог описывает конкретные проекты. Здесь **нет** самих RTL, скетчей, ROM или битстримов. Код, история изменений, лицензии и релизы остаются в исходных репозиториях.

Поля:

- `id`: устойчивый машинный идентификатор.
- `hardware_class`: `FPGA`, `MCU`, `SBC` или `HYBRID`.
- `board_ids`: ссылки на `platforms.json`; пустой список допустим для коллекций с несколькими неопределёнными конфигурациями.
- `evidence_level`: `discovered`, `source_documented`, `build_pass`, `operator_board_pass` или `candidate`.
- `distribution.status`: `released`, `source_only` или `collection`. Наличие релиза не гарантирует аппаратного теста.
- `distribution.sha256` и `distribution.file` обязательны для зарегистрированного готового FPGA `.fs`.
- `license_note` и `notes`: пределы использования, неоднозначности, ограничения прав.

Не трактуйте класс платформы как механизм автоматического определения платы. Для первой выпускаемой FPGA-конфигурации разрешена только **Tang Nano 9K**.

### Проверка без сетевых запросов

```powershell
.\tools\check_catalog.ps1
```

Скрипт проверяет валидность JSON, уникальность ID, соответствие платформ, обязательные поля и правильный формат SHA-256. Он **не** подключается к FPGA, не скачивает файлы и не доказывает доступность URL.

## EN

This catalog separates **board identity**, **game source**, **evidence level**, and **distribution status**. A public binary is not by itself a hardware certification. No third-party or original game sources are mirrored into KonSol.

Use the bundled PowerShell validator for structural checks. Keep status claims conservative and verify the exact board/bitstream pair before adding a browser loader profile.
