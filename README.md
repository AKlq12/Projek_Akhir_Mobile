# FitPro - Aplikasi Mobile Fitness

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white) ![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

FitPro adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu pengguna memantau kesehatan, melacak aktivitas olahraga, dan mencapai target kebugaran mereka. Aplikasi ini dilengkapi dengan berbagai fitur modern termasuk integrasi AI sebagai pelatih kebugaran, sensor perangkat keras (accelerometer & gyroscope), pelacak lokasi berlari, hingga autentikasi menggunakan sidik jari/wajah.

## 🌟 Fitur Utama

*   **🔒 Autentikasi Super Aman:** Login menggunakan integrasi **Biometrik** (Fingerprint/FaceID). Mendukung pendaftaran akun dan manajemen sesi via **Supabase**.
*   **🤖 AI Fitness Coach:** Chat eksklusif bersama pelatih kebugaran berbasis AI, didukung oleh **Google Gemini Pro**, siap memberikan saran latihan dan nutrisi kapan saja.
*   **🏃‍♂️ Melacak Latihan Secara Real-Time:** 
    *   **Pedometer:** Menghitung jumlah langkah setiap harinya (Data Sensor API).
    *   **Motion Tracker:** Integrasi *Gyroscope* untuk mendeteksi gerakan dalam sesi mini game "Reaction Reflex".
    *   **Maps & LBS:** Melacak rute lari langsung via peta digital dengan kalkulasi jarak yang presisi.
*   **📊 Analitik Kebugaran:** Grafik interaktif untuk memonitor progres latihan, berat badan, dan durasi istirahat menggunakan `fl_chart`.
*   **🌎 Fitur Penunjang Tambahan:**
    *   **Jam Dunia (World Clock):** Melihat lebih dari 50+ zona waktu secara global.
    *   **Konverter Mata Uang:** API Konversi langsung di dalam aplikasi.
    *   **Notifikasi Pengingat:** Sistem push-notification lokal (Workout reminders).
*   **💾 Offline Mode & Performa Cepat:** Penyimpanan data lokal (*caching*) yang diatur menggunakan arsitektur handal `hive_ce`.

## 🛠️ Tech Stack & Library

Aplikasi ini menggunakan teknologi yang modern dan andal:

*   **Framework Utama:** Flutter SDK ^3.11.1
*   **State Management:** Provider
*   **Backend & Database:** Supabase (`supabase_flutter`)
*   **Keamanan:** `flutter_secure_storage`, `crypto`, `local_auth`
*   **Penyimpanan Lokal:** `hive_ce`
*   **Kecerdasan Buatan (AI):** `google_generative_ai` (Gemini Pro)
*   **Location & Sensor:** `geolocator`, `flutter_map`, `sensors_plus`, `pedometer`
*   **Jaringan/API:** `http`, `dio`

## 🚀 Memulai Proyek (Getting Started)

### Prasyarat Asumsi
Pastikan Anda sudah menginstal:
1.  [Flutter SDK](https://docs.flutter.dev/get-started/install) terbaru.
2.  Android Studio / VS Code dengan plugin Flutter yang dikonfigurasi.
3.  Akun [Supabase](https://supabase.com/), [Wger](https://wger.de/), [Exchangerate-api](https://www.exchangerate-api.com/), dan [Google AI Studio (Gemini)](https://aistudio.google.com/apikey).

### Instalasi & Setup

1. **Clone repository ini**
   ```bash
   git clone https://github.com/AKlq12/Projek_Akhir_Mobile.git
   cd aplikasi_fitness
   ```

2. **Install semua dependencies**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Environment / Variabel Lingkungan**
   Siapkan kredensial API Anda dengan menggandakan file konfigurasi:
   ```bash
   cp .env.example .env
   ```
   Buka file `.env` di teks editor, dan isi dengan kredensial API Anda:
   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJI...
   WGER_API_KEY=your_wger_api_key_here
   WGER_BASE_URL=https://wger.de/api/v2
   GEMINI_API_KEY=AIzaSy...
   EXCHANGE_RATE_API_KEY=your_exchange_rate_api_key_here
   EXCHANGE_RATE_BASE_URL=https://v6.exchangerate-api.com/v6
   ```

4. **Migrasi Database Supabase**
   Terdapat file konfigurasi SQL bernama `supabase_migration.sql` pada root direktori. Eksekusi (*run*) perintah SQL yang ada pada file tersebut ke dalam **SQL Editor** di *dashboard* Supabase proyek Anda untuk membuat seluruh tabel dan fungsi yang diwajibkan oleh struktur aplikasi FitPro.

5. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```

## 👥 Kontribusi

Silakan buat *pull request* untuk pembaruan fitur, perbaikan bug, atau optimasi koding. Segala bentuk *feedback* sangat kami hargai.

## 📄 Lisensi

Projek Tugas Akhir Mobile - Aplikasi Fitness FitPro.
