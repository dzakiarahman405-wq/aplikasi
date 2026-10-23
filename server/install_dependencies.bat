@echo off
title Install Dependensi PC Remote
cd /d "%~dp0"

echo ========================================================
echo        MEMASANG DEPENDENSI LENGKAP PC REMOTE
echo ========================================================
echo.

python -m pip install --upgrade pip
python -m pip install -r requirements.txt

echo.
echo ========================================================
echo Instalasi selesai! Anda sekarang bisa menjalankan start.bat
echo ========================================================
pause
