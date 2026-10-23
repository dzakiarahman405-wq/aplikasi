@echo off
setlocal enabledelayedexpansion
title Upload ke GitHub Repository
cd /d "%~dp0"

echo ========================================================
echo          UPLOAD PROYEK KE GITHUB REPOSITORY
echo ========================================================
echo.

:: 1. Hapus .git nested di dalam mobile_flutter jika ada
if exist "mobile_flutter\.git" (
    echo [1/5] Merapikan sub-folder...
    rmdir /s /q "mobile_flutter\.git" 2>nul
)

:: 2. Inisialisasi Git di root jika belum ada
if not exist ".git" (
    echo [2/5] Menginisialisasi Git repository...
    git init
    git branch -M main
)

:: 3. Tambahkan semua file dan commit
echo [3/5] Menyiapkan file untuk di-upload...
git add .
git commit -m "Initial commit - PC Remote with Auto APK Build"

:: 4. Minta URL Repository dari User jika remote belum diatur
git remote get-url origin >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ========================================================
    echo Silakan masukkan URL GitHub Repository Anda.
    echo Contoh: https://github.com/username/nama-repo.git
    echo ========================================================
    set /p REPO_URL="URL GitHub: "
    if "!REPO_URL!"=="" (
        echo [ERROR] URL GitHub tidak boleh kosong!
        pause
        exit /b
    )
    git remote add origin !REPO_URL!
) else (
    echo [INFO] Remote origin sudah terpasang.
)

:: 5. Push ke GitHub
echo.
echo [4/5] Mengupload ke GitHub (git push)...
git push -u origin main --force

if %errorlevel% equ 0 (
    echo.
    echo ========================================================
    echo  SUKSES! Semua file berhasil di-upload ke GitHub!
    echo ========================================================
    echo.
    echo Buka repo GitHub Anda:
    echo 1. Lihat file kodingan server dan mobile_flutter
    echo 2. Buka tab "Actions" di GitHub untuk melihat
    echo    proses pembuatan file APK Android otomatis!
) else (
    echo.
    echo [PERHATIAN] Gagal melakukan push. Pastikan:
    echo 1. Anda sudah login ke GitHub (git / GitHub Desktop / Personal Access Token)
    echo 2. URL repository sudah benar
)

echo.
pause
