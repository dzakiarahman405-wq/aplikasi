# 📱 PC Native Remote Control (Ultra-Low Latency)

Aplikasi remote control komputer (Windows PC/Laptop) melalui smartphone secara native dengan latensi sangat rendah, kontrol gestur presisi, live screen mirroring 30-60 FPS, dan integrasi hardware.

---

## 🏗️ Struktur Proyek

```
testing aplikasi/
├── server/                     # Sisi PC (Windows Agent / Server)
│   ├── main.py                 # Core Server (WebSockets, HTTP PWA, Screen Stream & UDP)
│   ├── win_input.py            # Win32 SendInput & Media Controller (Zero-Lag ctypes)
│   ├── screen_capture.py       # High-performance screen capture (MSS + PIL)
│   ├── requirements.txt        # Dependensi Python
│   ├── run_server.bat          # Script 1-klik untuk instalasi & menjalankan server
│   ├── quick_run.bat           # Jalankan server langsung
│   └── static/                 # Embedded Mobile Web Remote (PWA Siap Pakai)
│       ├── index.html          # UI Touchscreen Cyber Dark Theme
│       ├── style.css           # Styling responsif, glassmorphism, no rubber-band
│       ├── app.js              # Gesture engine (tap, drag, 2-finger scroll, haptics)
│       └── manifest.json       # Dukungan install PWA ke homescreen HP
│
├── mobile_flutter/             # Sisi Smartphone (Native Flutter Client)
│   ├── pubspec.yaml            # Dependensi Flutter
│   ├── lib/
│   │   ├── main.dart           # Entry point & Dark Theme Material 3
│   │   ├── services/
│   │   │   └── remote_service.dart # Dual Channel (WebSocket + Raw UDP)
│   │   └── screens/
│   │       ├── connect_screen.dart     # Input IP & PIN auto-save
│   │       ├── dashboard_screen.dart   # Bottom navigation bar
│   │       ├── trackpad_view.dart      # Trackpad gestur sentuhan & tombol fisik
│   │       ├── shortcuts_view.dart     # Keyboard, Windows shortcuts, audio & power
│   │       └── screen_mirror_view.dart # Live screen mirror dengan tap interaktif
│   └── android/
│       └── app/src/main/AndroidManifest.xml
│
└── README.md
```

---

## ⚡ Cara Menjalankan (Sangat Cepat & Mudah)

### Langkah 1: Jalankan Server di PC

Pastikan PC dan Smartphone terhubung ke **jaringan Wi-Fi / Hotspot yang sama**.

**Opsi 1 (1-Klik):**
Cukup double-click file:
`server\run_server.bat` atau `server\quick_run.bat`

**Opsi 2 (Via Terminal / PowerShell):**
```powershell
cd "C:\testing aplikasi\server"
pip install -r requirements.txt
python main.py
```

Setelah server aktif, terminal akan menampilkan URL dan QR Code:
```
============================================================
🚀 NATIVE PC REMOTE SERVER SEDANG BERJALAN
============================================================
👉 Buka browser di Smartphone Anda:
   http://192.168.1.15:5000
============================================================
```

---

### Langkah 2: Mengontrol dari Smartphone

Anda memiliki **2 Pilihan Client**:

#### Pilihan A: Remote Instan via Browser / PWA (Rekomendasi Utama - Tanpa Perlu Install SDK)
1. Buka browser (Chrome / Safari) di HP Anda.
2. Ketik URL yang muncul di terminal PC (contoh: `http://192.168.1.15:5000`) atau scan QR Code-nya.
3. Anda langsung mendapatkan remote kontrol penuh!
4. *(Tips Native):* Tekan tombol menu browser di HP lalu pilih **"Tambahkan ke Layar Utama" (Add to Home Screen)**. Aplikasi akan menjadi aplikasi mandiri di HP tanpa address bar browser, lengkap dengan haptic vibration.

#### Pilihan B: Aplikasi Native Flutter
Jika Anda ingin mengompilasi file APK Android sendiri:
1. Buka folder `mobile_flutter` di terminal atau Android Studio.
2. Jalankan perintah:
   ```bash
   flutter pub get
   flutter run
   ```
3. Atau build APK:
   ```bash
   flutter build apk --release
   ```
4. Buka aplikasi di HP, masukkan IP PC yang tampil di server, lalu tekan **Sambungkan**.

---

## 🎮 Panduan Gestur & Fitur Utama

| Gestur / Kontrol | Aksi di PC |
| :--- | :--- |
| **Geser 1 Jari** | Menggerakkan kursor mouse dengan akselerasi halus |
| **Ketuk 1 Jari (Tap)** | Klik Kiri mouse + Haptic feedback |
| **Ketuk 2 Jari** | Klik Kanan mouse |
| **Geser 2 Jari (Up/Down)** | Scroll halaman vertikal |
| **Tekan Lama (>380ms)** | Drag & Drop (menahan klik kiri saat menggeser objek) |
| **Side Scrollbar** | Slider cepat di sisi kanan untuk scroll dokumen panjang |
| **Keyboard & Quick Keys** | Mengetik teks langsung, tombol `Esc`, `Tab`, `Enter`, `Backspace` |
| **Windows Shortcuts** | `Win`, `Desktop (Win+D)`, `Alt+Tab`, `Alt+F4`, `Copy`, `Paste`, `Undo` |
| **Audio & Media** | Volume Up/Down, Mute, Play/Pause, Next/Prev Track |
| **Power Control** | Kunci Layar (`Lock`), `Sleep`, `Restart`, dan `Shutdown` (dengan konfirmasi) |
| **Live Screen Mirroring** | Melihat layar PC secara live dan menyentuh layar HP untuk mengklik koordinat di PC |

---

## 🔒 Konfigurasi Keamanan (PIN)

Secara default, server terbuka untuk siapa saja di jaringan Wi-Fi lokal yang sama. Jika Anda ingin menambahkan proteksi PIN:

Jalankan server dengan variabel environment:
```powershell
$env:REMOTE_PIN = "1234"; python main.py
```
Atau edit nilai `CONFIG_PIN = "1234"` di dalam file `server/main.py`. Klien akan diminta memasukkan PIN sebelum dapat mengontrol PC.
