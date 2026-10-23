# 🚀 Panduan Mempublish Aplikasi PC Native Remote

Dokumen ini berisi panduan lengkap untuk mempublish aplikasi PC Remote Anda, baik ke smartphone (menjadi APK / Aplikasi Mandiri) maupun ke internet (agar bisa diakses dari luar rumah).

---

## 1. ⚡ Persiapan Cepat (1-Klik Install Semua Kebutuhan)

Cukup double-click file:
```
install_all.bat
```
Skrip ini akan otomatis:
- Memperbarui `pip`
- Menginstall seluruh pustaka server PC (`aiohttp`, `mss`, `Pillow`, `qrcode`, `psutil`)
- Menyiapkan compiler untuk build

---

## 2. 📱 Mempublish Aplikasi ke HP (Tanpa Browser)

### Opsi A: Instal Langsung Jadi Aplikasi Mandiri di HP (Selesai dalam 10 Detik)
1. Jalankan `start.bat` di PC.
2. Di HP Anda, buka link server (contoh: `http://192.168.1.15:5000`).
3. Tekan menu titik tiga **(⋮)** di browser HP (Chrome / Safari).
4. Pilih **"Instal Aplikasi"** atau **"Tambahkan ke Layar Utama" (Add to Home screen)**.
5. **Selesai!** Aplikasi sekarang sudah terpasang di menu aplikasi HP Anda, memiliki ikon sendiri, berjalan layar penuh, tanpa address bar browser, dan dilengkapi fitur getaran haptic.

### Opsi B: Build Menjadi File Installer Android (`.apk`)
- Jika Anda memiliki **Flutter SDK** di PC:
  Cukup double-click:
  ```
  build_apk.bat
  ```
  File `PC-Remote.apk` akan langsung ter-generate otomatis di folder utama!

- Jika Anda ingin **Otomatis Build di Cloud via GitHub (Gratis & Bebas Repot)**:
  1. Upload folder proyek ini ke akun GitHub Anda.
  2. Workflow di `.github/workflows/build-apk.yml` akan langsung mengompilasi APK secara otomatis.
  3. Buka tab **Actions** di repo GitHub Anda, lalu download file `PC-Remote-Release-APK.zip` yang berisi installer APK siap pakai!

---

## 3. 🌐 Mempublish Server ke Internet (Akses Luar Rumah / 4G / 5G)

Secara default, PC Remote berjalan di jaringan Wi-Fi lokal. Jika Anda ingin mengontrol PC dari **kantor, kampus, atau luar kota** menggunakan kuota HP:

1. Double-click file:
   ```
   publish_online.bat
   ```
2. Skrip akan otomatis mengaktifkan **Cloudflare Secure Tunnel** (100% gratis, tanpa perlu daftar akun, dan tanpa perlu setting router/port-forwarding).
3. Anda akan mendapatkan URL HTTPS publik, misalnya:
   ```
   https://random-words.trycloudflare.com
   ```
4. Buka alamat tersebut di HP Anda dari jaringan mana saja di seluruh dunia!

---

## 4. 💻 Fitur Baru: Remote CMD / Windows Terminal di HP

Aplikasi kini dilengkapi tab **CMD**:
- Anda dapat mengecek status PC dari HP: `ipconfig`, `tasklist`, `systeminfo`, `dir`, dll.
- Output perintah Windows langsung muncul rapi di layar HP Anda secara real-time.
