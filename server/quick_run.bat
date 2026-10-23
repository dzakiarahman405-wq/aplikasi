@echo off
title PC Remote Agent Server (Quick Run)
cd /d "%~dp0"
python main.py
if %errorlevel% neq 0 (
    echo.
    echo Ada modul yang belum terpasang. Menjalankan instalasi...
    pip install aiohttp mss Pillow qrcode psutil
    python main.py
)
pause
