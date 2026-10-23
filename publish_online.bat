@echo off
setlocal enabledelayedexpansion
title Publish PC Remote Online (Akses Internet / Luar Rumah)
cd /d "%~dp0"

echo ========================================================
echo        PUBLISH PC REMOTE KE INTERNET (ONLINE)
echo ========================================================
echo.
echo Fitur ini memungkinkan Anda mengontrol PC dari luar rumah
echo menggunakan kuota/data HP (4G/5G) tanpa perlu Wi-Fi yang sama.
echo.

:: Cek apakah cloudflared sudah ada
if not exist "server\cloudflared.exe" (
    echo [INFO] Mengunduh Cloudflare Tunnel (Aman, Gratis, & Tanpa Perlu Akun)...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe' -OutFile 'server\cloudflared.exe'"
    if !errorlevel! neq 0 (
        echo [GAGAL] Gagal mengunduh cloudflared secara otomatis.
        echo Silakan unduh manual dari https://github.com/cloudflare/cloudflared/releases
        echo lalu simpan sebagai server\cloudflared.exe
        pause
        exit /b
    )
    echo [OK] Cloudflare Tunnel berhasil diunduh!
)

:: Pastikan server lokal aktif terlebih dahulu
echo.
echo [1/2] Menjalankan Server Lokal di background...
start /b cmd /c "start.bat"

timeout /t 3 >nul

echo [2/2] Membuka Terowongan Online Aman (HTTPS)...
echo.
echo ========================================================
echo Tunggu beberapa detik hingga muncul link 'https://....trycloudflare.com'
echo Buka link tersebut di browser / aplikasi HP Anda dari MANA SAJA!
echo ========================================================
echo.

server\cloudflared.exe tunnel --url http://127.0.0.1:5000

pause
