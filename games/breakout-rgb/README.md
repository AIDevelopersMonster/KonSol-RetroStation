# BREAKOUT RGB v0.1.0 — внешний исходный проект

**Статус:** игра № 2 в KonSol RetroStation. Эта папка — **ссылка на исходники**, а не копия игрового RTL.

Оригинальный проект хранится в репозитории **Sipeed-FPGA**. Для разработки, сборки и истории изменений используйте его:

- **[Исходники, Verilog, тесты, сборка и README](https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/breakout-rgb)**
- **[Проверенный релиз BREAKOUT RGB v0.1.0](https://github.com/AIDevelopersMonster/Sipeed-FPGA/releases/tag/konsol-breakout-rgb-v0.1.0)**
- **[Единая браузерная консоль KonSol RetroStation](https://aidevelopersmonster.github.io/KonSol-RetroStation/console/)**

Плата: **Sipeed Tang Nano 9K (GW1NR-9C)**; видеовыход HDMI, управление UART 115200 8N1. Программирование только в **SRAM**, не в Flash.

Бинарник релиза: `pikosol_breakout_rgb_nano9k.fs` (2 070 601 байт).

SHA-256: `4cf80dbd008b0d41d4316bf63db952190c03940a4ffb1ffc00cab09210ae8789`.

**Управление:** A/D или ←/→ — ракетка; P — запуск мяча; R — перезапуск; 1–4 — палитра.

Исходный репозиторий и этот указатель намеренно не дублируют RTL, зависимости Gowin и файлы сборки. [Все семь игр](../README.md).
