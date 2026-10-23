@echo off
setlocal enabledelayedexpansion
title Setup dan Persiapan Publish PC Remote
cd /d "%~dp0"

echo ========================================================
echo       MEMASANG SEMUA KEBUTUHAN APLIKASI PC REMOTE
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
    echo [ERROR] Python belum terpasang di sistem!
    echo Silakan install Python terlebih dahulu dari https://www.python.org/
    echo Pastikan centang "Add python.exe to PATH" saat menginstall.
    pause
    exit /b
)

echo [1/3] Memperbarui pip & memasang dependensi server PC...
%PY_CMD% -m pip install --upgrade pip --quiet
%PY_CMD% -m pip install -r server\requirements.txt

if !errorlevel! equ 0 (
    echo [OK] Semua modul Python berhasil dipasang!
) else (
    echo [PERINGATAN] Ada modul yang gagal dipasang. Mencoba satu per satu...
    %PY_CMD% -m pip install aiohttp mss Pillow qrcode psutil
)
echo.

:: 2. Cek Flutter & Java untuk Build APK
echo [2/3] Memeriksa compiler APK Android...
where flutter >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Flutter SDK terdeteksi!
    echo Mengunduh paket dependensi Flutter...
    cd mobile_flutter
    call flutter pub get
    cd ..
    echo [OK] Flutter siap untuk build APK (Jalankan: build_apk.bat)
) else (
    echo [INFO] Flutter belum terpasang di PC.
    echo Jangan khawatir! Anda tetap bisa mempublish APK secara otomatis & gratis
    echo menggunakan GitHub Actions Cloud Builder tanpa perlu install Flutter (5+ GB) di PC.
)
echo.

:: 3. Ringkasan
echo [3/3] Menyiapkan launcher...
echo.
echo ========================================================
echo             SEMUA KEBUTUHAN SELESAI DISIAPKAN!
echo ========================================================
echo.
echo Pilihan berikutnya untuk Anda:
echo  1. Jalankan Server: Double-click 'start.bat'
echo  2. Buat File APK: Double-click 'build_apk.bat'
echo  3. Publish Online (Akses Luar Rumah): Double-click 'publish_online.bat'
echo.
pause
