# 🏋️ FitPro - Aplikasi Mobile Fitness
## Implementation Plan

Aplikasi mobile fitness menggunakan Flutter yang terintegrasi dengan **wger.de API** untuk data exercise/workout, **Supabase** untuk database & autentikasi, serta berbagai fitur tambahan sesuai ketentuan Tugas Akhir mata kuliah TPM.

---

## Pemetaan Fitur dengan Ketentuan Tugas Akhir

| # | Ketentuan | Implementasi di FitPro |
|---|-----------|------------------------|
| 1 | Konsep projek akhir | Aplikasi Fitness: browse exercise, buat workout plan, tracking, nutrisi |
| 2 | Login dengan enkripsi + session | Supabase Auth (bcrypt hashing server-side), JWT session, `flutter_secure_storage` |
| 3 | Login biometric | `local_auth` package — fingerprint/face ID |
| 4 | Database/penyimpanan | **Supabase PostgreSQL** (remote) + **Hive** (local cache) |
| 5 | Web Service/API + LBS | **wger.de API** (exercise/workout) + **OpenStreetMap** (nearby gyms) |
| 6 | Bottom Navigation + Profil + Saran Kesan + Logout | 5-tab bottom nav: Home, Exercises, Tools, AI Chat, Profile |
| 7 | Konversi mata uang + waktu | **ExchangeRate-API** (160+ currencies) + **timezone** package (semua zona waktu dunia) |
| 8 | Minimal 2 sensor | **Accelerometer** (step counter/pedometer) + **Gyroscope** (shake detection untuk shuffle exercise) |
| 9 | AI/ML dan LLM | **Google Gemini API** — AI Fitness Coach chatbot |
| 10 | Mini games | **Reaction Reflex Game** — test kecepatan reaksi (fitness-themed) |
| 11 | Pencarian + pemilihan + notifikasi | Search & filter exercise + **flutter_local_notifications** (workout reminders) |

---

## Arsitektur Aplikasi

```
┌─────────────────────────────────────────────┐
│               Flutter App                    │
├─────────────────────────────────────────────┤
│  UI Layer (Screens & Widgets)               │
│  ↕                                           │
│  State Management (Provider)                │
│  ↕                                           │
│  Service Layer (API Services)               │
│  ↕                                           │
│  Local Storage (Hive + Secure Storage)      │
└─────────────────┬───────────────────────────┘
                  │
    ┌─────────────┼─────────────┐
    ↓             ↓             ↓
┌─────────┐ ┌─────────┐ ┌──────────┐
│ Supabase│ │ wger.de │ │ External │
│ Auth+DB │ │  API    │ │  APIs    │
└─────────┘ └─────────┘ └──────────┘
                          │
              ┌───────────┼───────────┐
              ↓           ↓           ↓
        ExchangeRate  Google      OpenStreet
           API       Gemini       Map (OSM)
```

---

## Struktur Folder

```
lib/
├── main.dart                          # Entry point + Supabase init
├── app.dart                           # MaterialApp + routing + theme
│
├── config/
│   ├── constants.dart                 # API URLs, keys, config values
│   ├── routes.dart                    # Named routes
│   └── theme.dart                     # App theme (dark/light, colors, typography)
│
├── core/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── exercise_model.dart
│   │   ├── exercise_category_model.dart
│   │   ├── muscle_model.dart
│   │   ├── workout_model.dart
│   │   ├── workout_log_model.dart
│   │   ├── nutrition_model.dart
│   │   └── gym_model.dart
│   │
│   ├── services/
│   │   ├── auth_service.dart          # Supabase Auth + biometric
│   │   ├── wger_api_service.dart      # wger.de API calls
│   │   ├── supabase_service.dart      # Supabase DB queries
│   │   ├── currency_service.dart      # ExchangeRate API
│   │   ├── gemini_service.dart        # Google Gemini AI
│   │   ├── location_service.dart      # Geolocator + gym search
│   │   ├── notification_service.dart  # Local notifications
│   │   └── sensor_service.dart        # Accelerometer + Gyroscope
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── exercise_provider.dart
│   │   ├── workout_provider.dart
│   │   ├── profile_provider.dart
│   │   ├── currency_provider.dart
│   │   ├── timezone_provider.dart
│   │   ├── sensor_provider.dart
│   │   ├── chat_provider.dart
│   │   └── notification_provider.dart
│   │
│   └── widgets/
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       ├── loading_widget.dart
│       ├── exercise_card.dart
│       ├── workout_card.dart
│       ├── bottom_nav_bar.dart
│       └── stat_card.dart
│
├── screens/
│   ├── splash_screen.dart             # Splash + auto-login check
│   ├── auth/
│   │   ├── login_screen.dart          # Email/password + biometric
│   │   └── register_screen.dart       # Sign up
│   │
│   ├── home/
│   │   └── home_screen.dart           # Dashboard: stats, today's workout, steps
│   │
│   ├── exercise/
│   │   ├── exercise_list_screen.dart   # Browse + search + filter
│   │   ├── exercise_detail_screen.dart # Detail + images + muscles
│   │   └── exercise_category_screen.dart
│   │
│   ├── workout/
│   │   ├── workout_list_screen.dart    # User's workout plans
│   │   ├── workout_create_screen.dart  # Create new workout
│   │   ├── workout_detail_screen.dart  # Workout detail & exercises
│   │   └── workout_session_screen.dart # Active workout (with sensor)
│   │
│   ├── tools/
│   │   ├── tools_menu_screen.dart      # Grid menu for tools
│   │   ├── currency_converter_screen.dart
│   │   ├── timezone_converter_screen.dart
│   │   ├── nearby_gym_screen.dart      # Map + gym list (LBS)
│   │   └── mini_game_screen.dart       # Reaction Reflex Game
│   │
│   ├── ai_chat/
│   │   └── ai_chat_screen.dart         # AI Fitness Coach (Gemini)
│   │
│   └── profile/
│       ├── profile_screen.dart         # User profile + photo + stats
│       ├── edit_profile_screen.dart    # Edit profile data
│       ├── saran_kesan_screen.dart     # Saran & Kesan TPM
│       └── settings_screen.dart        # Notification settings, logout
```

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # === Supabase (Auth + Database) ===
  supabase_flutter: ^2.8.4

  # === Security & Storage ===
  flutter_secure_storage: ^9.2.4
  crypto: ^3.0.6
  hive_ce: ^2.6.0
  hive_ce_flutter: ^2.3.0

  # === State Management ===
  provider: ^6.1.2

  # === Network ===
  http: ^1.3.0
  dio: ^5.8.0

  # === Authentication ===
  local_auth: ^2.3.0              # Biometric

  # === UI & Design ===
  google_fonts: ^6.2.1
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  lottie: ^3.3.1
  fl_chart: ^0.70.2
  flutter_svg: ^2.0.17
  flutter_animate: ^4.5.2

  # === Location & Maps (LBS) ===
  geolocator: ^13.0.2
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  geocoding: ^3.0.0

  # === Sensors ===
  sensors_plus: ^6.1.1
  pedometer: ^4.0.2

  # === AI/LLM ===
  google_generative_ai: ^0.4.7

  # === Notifications ===
  flutter_local_notifications: ^18.0.1

  # === Currency & Time ===
  intl: ^0.19.0
  timezone: ^0.10.0

  # === Image ===
  image_picker: ^1.1.2
  image_cropper: ^8.0.2

  # === Utils ===
  url_launcher: ^6.3.1
  uuid: ^4.5.1
  connectivity_plus: ^6.1.1
  permission_handler: ^11.3.1
  flutter_dotenv: ^5.2.1
```

---

## Database Schema (Supabase PostgreSQL)

```sql
-- Users profile (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  date_of_birth DATE,
  gender TEXT,
  height_cm REAL,
  weight_kg REAL,
  fitness_goal TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workout logs
CREATE TABLE workout_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  exercise_id INT NOT NULL,
  exercise_name TEXT NOT NULL,
  sets INT,
  reps INT,
  weight_kg REAL,
  duration_minutes INT,
  notes TEXT,
  performed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Favorite exercises
CREATE TABLE favorite_exercises (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  exercise_id INT NOT NULL,
  exercise_name TEXT NOT NULL,
  category TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, exercise_id)
);

-- Daily step count
CREATE TABLE step_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  step_count INT NOT NULL,
  date DATE NOT NULL,
  distance_km REAL,
  calories_burned REAL,
  UNIQUE(user_id, date)
);

-- Workout plans
CREATE TABLE workout_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  day_of_week TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workout plan exercises (join table)
CREATE TABLE plan_exercises (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  plan_id UUID REFERENCES workout_plans(id) ON DELETE CASCADE,
  exercise_id INT NOT NULL,
  exercise_name TEXT NOT NULL,
  target_sets INT,
  target_reps INT,
  target_weight_kg REAL,
  sort_order INT DEFAULT 0
);

-- Saran & Kesan
CREATE TABLE saran_kesan (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  saran TEXT,
  kesan TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notification settings
CREATE TABLE notification_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  workout_reminder BOOLEAN DEFAULT true,
  reminder_time TIME DEFAULT '08:00',
  step_goal INT DEFAULT 10000
);

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE step_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE saran_kesan ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies (user can only access their own data)
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Repeat similar policies for other tables...
```

---

## wger.de API Endpoints

| Endpoint | Method | Deskripsi |
|----------|--------|-----------|
| `/api/v2/exercisecategory/` | GET | Kategori exercise (Arms, Legs, Chest, dll) |
| `/api/v2/exercise/?language=2&format=json` | GET | List exercise (language=2 untuk English) |
| `/api/v2/exerciseinfo/{id}/` | GET | Detail exercise + images + muscles |
| `/api/v2/exerciseimage/` | GET | Gambar exercise |
| `/api/v2/muscle/` | GET | Data otot |
| `/api/v2/equipment/` | GET | Peralatan gym |

---

## Phase Implementasi

### Phase 1: Project Setup
- Konfigurasi pubspec.yaml dependencies
- Setup `.env` file untuk API keys
- Konfigurasi Android/iOS permissions

### Phase 2: Theme & Config
- Dark mode theme dengan Material Design 3
- Color palette, typography, component themes
- Named routes configuration
- Constants & API URLs

### Phase 3: Authentication
- Supabase Auth (email/password + JWT session)
- Biometric login (fingerprint/face ID)
- Splash screen + auto-login
- Login & register screens

### Phase 4: Database Setup
- Supabase tables creation (SQL)
- RLS policies
- Supabase service layer
- Hive local cache setup

### Phase 5: Core Fitness (wger.de API)
- Exercise list with search & filter
- Exercise detail with images
- Exercise categories
- Favorite exercises

### Phase 6: Home Dashboard
- Daily stats (steps, calories, streak)
- Today's workout preview
- Quick actions
- Weekly charts

### Phase 7: Workout Management
- CRUD workout plans
- Add exercises to plans
- Active workout session
- Workout logging

### Phase 8: Tools
- Currency converter (160+ currencies)
- Timezone converter (WIB, WITA, WIT, London + global)
- Tools menu grid

### Phase 9: LBS - Nearby Gyms
- OpenStreetMap integration
- Geolocator for user position
- Overpass API for gym search
- Map with markers

### Phase 10: Sensors
- Accelerometer/Pedometer (step counter)
- Gyroscope (shake detection)
- Sensor data visualization

### Phase 11: AI/LLM (Google Gemini)
- AI Fitness Coach chatbot
- Chat UI with message bubbles
- Streaming responses
- Quick prompt buttons

### Phase 12: Mini Game
- Reaction Reflex Game
- Random exercise icons
- Score & rating system
- High score leaderboard

### Phase 13: Profile & Saran Kesan
- Profile screen with avatar
- Edit profile
- Saran & Kesan TPM form
- Settings

### Phase 14: Notifications & Polish
- Local notifications setup
- Workout reminders
- Step goal notifications
- Final testing & polish

---

## API Keys yang Diperlukan

| Service | URL | Gratis? |
|---------|-----|---------|
| Supabase | https://supabase.com | ✅ Ya (free tier) |
| ExchangeRate-API | https://exchangerate-api.com | ✅ Ya (1500 req/bulan) |
| Google Gemini | https://aistudio.google.com | ✅ Ya (free tier) |
| wger.de | https://wger.de | ✅ Ya (buat akun) |

---

## Estimasi

| Kategori | Jumlah File | Estimasi LOC |
|----------|-------------|-------------|
| Config | 4 | ~300 |
| Models | 7 | ~500 |
| Services | 8 | ~1500 |
| Providers | 9 | ~1200 |
| Screens | 18 | ~4500 |
| Widgets | 7 | ~700 |
| Main/App | 2 | ~150 |
| **Total** | **~55 files** | **~8850 LOC** |
