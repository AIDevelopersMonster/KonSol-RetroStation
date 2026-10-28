# Семь FPGA-игр KonSol RetroStation

Все семь игр доступны через [общую браузерную консоль](https://aidevelopersmonster.github.io/KonSol-RetroStation/console/) для **Tang Nano 9K**. Она принимает только точные SHA-256 прошивок и программирует **SRAM**.

| № | Игра | Каталог | Где находятся исходники |
|---|---|---|---|
| 1 | PONG RGB v1.2 | [pong-rgb](pong-rgb/README.md) | [Sipeed-FPGA](https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/pong-rgb) |
| 2 | BREAKOUT RGB v0.1.0 | [breakout-rgb](breakout-rgb/README.md) | [Sipeed-FPGA](https://github.com/AIDevelopersMonster/Sipeed-FPGA/tree/main/games/breakout-rgb) |
| 3 | K-BLOCKS RGB | [kblocks-rgb](kblocks-rgb/README.md) | Этот репозиторий |
| 4 | LIGHT CYCLES RGB | [lightcycles-rgb](lightcycles-rgb/README.md) | Этот репозиторий |
| 5 | SPACE PATROL RGB | [spacepatrol-rgb](spacepatrol-rgb/README.md) | Этот репозиторий |
| 6 | MAZE CHASE RGB | [mazechase-rgb](mazechase-rgb/README.md) | Этот репозиторий |
| 7 | MINI TD RGB | [minitd-rgb](minitd-rgb/README.md) | Этот репозиторий |

**Организация:** первые два каталога — только README-указатели на проверенные оригинальные проекты. Исходники и историю не копируем: избегаем расхождения двух версий. Остальные пять игр имеют собственные RTL, инструкции и результаты испытаний в этом репозитории.

Все семь профилей и SHA-256 зарегистрированы в [docs/console/profiles.json](../docs/console/profiles.json). Проверенные бинарники размещены в GitHub Releases соответствующих исходных репозиториев.
