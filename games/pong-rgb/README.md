# PONG RGB v1.2 — внешний исходный проект

**Статус:** игра № 1 в KonSol RetroStation. Эта папка — **ссылка на исходники**, а не копия игрового RTL.

Оригинальный проект хранится в репозитории **Sipeed-FPGA**. Для разработки, сборки и истории изменений используйте его:

- **[Исходники, Verilog, сборка, ограничения, README](https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/pong-rgb)**
- **[Проверенный релиз PONG RGB v1.2](https://github.com/AIDevelopersMonster/Sipeed-FPGA/releases/tag/pikosol-pong-rgb-v1.2)**
- **[Единая браузерная консоль KonSol RetroStation](https://aidevelopersmonster.github.io/KonSol-RetroStation/console/)**

Плата: **Sipeed Tang Nano 9K (GW1NR-9C)**; видеовыход HDMI, управление UART 115200 8N1. Программирование только в **SRAM**, не в Flash.

Бинарник релиза: `pikosol_pong_rgb_nano9k.fs` (2 070 601 байт).

SHA-256: `978d9bcff7c1ef1350f88af2c603a00b7d3bb6325ea39019ca57cf5091639f96`.

**Управление:** W/S — левая ракетка; I/K — правая; A — ИИ; 5/6/7 — сложность; 1–4 — палитра; R — перезапуск.

Исходный репозиторий и этот указатель намеренно не дублируют RTL, зависимости Gowin и файлы сборки. [Все семь игр](../README.md).
