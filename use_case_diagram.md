# Use Case Diagram - FitPro Mobile App

Berikut adalah Use Case Diagram untuk aplikasi FitPro Mobile yang mencakup seluruh fitur utama mulai dari autentikasi hingga alat fitness cerdas.

```mermaid
useCaseDiagram
    actor "User" as U
    actor "Supabase (Backend)" as S
    actor "Wger API (Exercises)" as W
    actor "Google Maps API" as G
    actor "AI Service" as AI

    package "FitPro Mobile Application" {
        usecase "Login & Register" as UC1
        usecase "OTP Verification" as UC2
        usecase "Edit Profile & Avatar" as UC3
        usecase "Manage Notifications" as UC4
        usecase "Submit Feedback" as UC5
        
        usecase "Browse Exercise Categories" as UC6
        usecase "Search & View Exercise Detail" as UC7
        
        usecase "Create Workout Plan" as UC8
        usecase "Manage Workout List" as UC9
        usecase "Execute Workout Session" as UC10
        
        usecase "Find Nearby Gyms" as UC11
        usecase "Shake for Random Exercise" as UC12
        usecase "Track Daily Steps" as UC13
        usecase "Play Mini Fitness Game" as UC14
        usecase "Currency & Timezone Converter" as UC15
        
        usecase "Chat with AI Assistant" as UC16
    }

    %% Relationships
    U --> UC1
    U --> UC3
    U --> UC4
    U --> UC5
    U --> UC6
    U --> UC7
    U --> UC8
    U --> UC9
    U --> UC10
    U --> UC11
    U --> UC12
    U --> UC13
    U --> UC14
    U --> UC15
    U --> UC16

    UC1 ..> UC2 : <<include>>
    
    %% External System Connections
    UC1 -- S
    UC3 -- S
    UC5 -- S
    UC7 -- W
    UC11 -- G
    UC16 -- AI
```

## Deskripsi Use Case

| No | Use Case | Deskripsi |
|---|---|---|
| 1 | **Login & Register** | Proses masuk atau pendaftaran akun pengguna menggunakan Supabase. |
| 2 | **OTP Verification** | Verifikasi kode OTP untuk memastikan keamanan akun saat pendaftaran. |
| 3 | **Edit Profile** | Mengubah informasi profil seperti nama, bio, dan foto profil (avatar). |
| 4 | **Exercise Management** | Menjelajahi katalog latihan berdasarkan kategori atau pencarian spesifik menggunakan data dari Wger API. |
| 5 | **Workout Planning** | Membuat jadwal latihan kustom, melihat daftar rencana, dan memulai sesi latihan. |
| 6 | **Nearby Gyms** | Mencari lokasi pusat kebugaran terdekat menggunakan integrasi Google Maps. |
| 7 | **Shake Exercise** | Fitur interaktif untuk mendapatkan rekomendasi latihan acak dengan menggoyangkan ponsel. |
| 8 | **Step Tracker** | Memantau jumlah langkah harian pengguna menggunakan sensor pedometer. |
| 9 | **AI Assistant** | Berinteraksi dengan chatbot AI untuk mendapatkan saran atau informasi seputar kebugaran. |

## Deskripsi Aktor

*   **User**: Pengguna utama aplikasi yang berinteraksi dengan seluruh fitur.
*   **Supabase**: Layanan backend yang menangani autentikasi, database, dan penyimpanan file.
*   **Wger API**: Sumber data eksternal untuk informasi latihan fisik.
*   **Google Maps API**: Layanan untuk menyediakan data lokasi dan peta untuk fitur gym terdekat.
*   **AI Service**: Provider AI (seperti Gemini atau OpenAI) yang mentenagai fitur chatbot.
