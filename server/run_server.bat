@echo off
title PC Remote Agent Server
cd /d "%~dp0"

echo ========================================================
echo         MEMULAI PC NATIVE REMOTE SERVER
echo ========================================================

:: Periksa apakah Python terpasang
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python tidak terdeteksi! Silakan pasang Python terlebih dahulu.
    pause
    exit /b
)

:: Buat virtual environment jika belum ada
if not exist "venv" (
    echo [INFO] Membuat virtual environment 'venv'...
    python -m venv venv
)

:: Aktifkan venv
call venv\Scripts\activate.bat

:: Pasang dependensi
echo [INFO] Memeriksa & memasang dependensi...
pip install -r requirements.txt --quiet

:: Jalankan server
echo [INFO] Menjalankan Server...
python main.py

pause
