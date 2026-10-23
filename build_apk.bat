@echo off
setlocal enabledelayedexpansion
title Build APK Android PC Remote
cd /d "%~dp0"

echo ========================================================
echo             BUILD APK ANDROID PC REMOTE
echo ========================================================
echo.

where flutter >nul 2>&1
if !errorlevel! neq 0 (
    echo [INFO] Flutter SDK belum terpasang di komputer ini.
    echo.
    echo Untuk membuat file installer APK, Anda memiliki 2 opsi:
    echo.
    echo OPSI 1: Otomatis via Cloud GitHub (Rekomendasi - Tidak perlu install apa-apa)
    echo   - Upload folder ini ke GitHub repo Anda
    echo   - GitHub Actions akan otomatis membuat file APK (.apk) siap download dalam 2 menit.
    echo.
    echo OPSI 2: Install Flutter SDK di PC
    echo   - Unduh Flutter dari: https://docs.flutter.dev/get-started/install/windows
    echo   - Ekstrak dan masukkan path flutter/bin ke Environment Variables (PATH)
    echo   - Jalankan kembali script ini!
    echo.
    pause
    exit /b
)

echo [1/3] Mengunduh dependensi Flutter...
cd mobile_flutter
call flutter pub get

echo [2/3] Memulai kompilasi file APK Release...
call flutter build apk --release

if !errorlevel! equ 0 (
    echo.
    echo [3/3] Kompilasi berhasil! Menyalin file APK ke folder utama...
    copy /y "build\app\outputs\flutter-apk\app-release.apk" "..\PC-Remote.apk" >nul
    cd ..
    echo.
    echo ========================================================
    echo  SUKSES! File APK telah dibuat:
    echo  Lokasi: C:\testing aplikasi\PC-Remote.apk
    echo ========================================================
    echo.
    echo Kirim file 'PC-Remote.apk' ke HP Anda dan langsung install!
) else (
    echo [ERROR] Terjadi kesalahan saat kompilasi APK.
    cd ..
)

echo.
pause
