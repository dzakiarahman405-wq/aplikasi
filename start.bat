@echo off
setlocal enabledelayedexpansion
title PC Remote Agent Launcher
cd /d "%~dp0\server"

echo ========================================================
echo         PC NATIVE REMOTE CONTROL - STARTER
echo ========================================================
echo.

:: 1. Deteksi Python
set "PY_CMD="

python --version >nul 2>&1
if !errorlevel! equ 0 (
    set "PY_CMD=python"
) else (
    py --version >nul 2>&1
    if !errorlevel! equ 0 (
        set "PY_CMD=py"
    )
)

if "%PY_CMD%"=="" (
    echo [ERROR] Python tidak ditemukan di sistem Anda!
    echo.
    echo Silakan install Python dari https://www.python.org/downloads/
    echo PENTING: Saat install, pastikan centang opsi "Add python.exe to PATH"
    echo.
    pause
    exit /b
)

echo [OK] Python terdeteksi: %PY_CMD%
%PY_CMD% --version
echo.

:: 2. Cek apakah aiohttp terpasang
%PY_CMD% -c "import aiohttp" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Paket lengkap terdeteksi. Memulai server utama (WebSocket + Stream)...
    echo.
    %PY_CMD% main.py
) else (
    echo [INFO] Menjalankan Server Standalone (Zero-Dependency)...
    echo (Server ini berjalan langsung dengan Python bawaan tanpa perlu install library!)
    echo.
    %PY_CMD% simple_server.py
)

if !errorlevel! neq 0 (
    echo.
    echo Terjadi kendala saat menjalankan server.
)

echo.
pause
