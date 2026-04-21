-- ============================================================================
-- FitPro — Supabase PostgreSQL Migration
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. PROFILES (extends auth.users)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
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

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. WORKOUT LOGS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS workout_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  exercise_id INT NOT NULL,
  exercise_name TEXT NOT NULL,
  sets INT,
  reps INT,
  weight_kg REAL,
  duration_minutes INT,
  notes TEXT,
  performed_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. FAVORITE EXERCISES
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS favorite_exercises (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  exercise_id INT NOT NULL,
  exercise_name TEXT NOT NULL,
  category TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, exercise_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. STEP LOGS (daily step count)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS step_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  step_count INT NOT NULL,
  date DATE NOT NULL,
  distance_km REAL,
  calories_burned REAL,
  UNIQUE(user_id, date)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. WORKOUT PLANS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS workout_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  day_of_week TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. PLAN EXERCISES (join table)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS plan_exercises (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  plan_id UUID REFERENCES workout_plans(id) ON DELETE CASCADE NOT NULL,
  exercise_id INT NOT NULL,
  exercise_name TEXT NOT NULL,
  target_sets INT,
  target_reps INT,
  target_weight_kg REAL,
  sort_order INT DEFAULT 0
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. SARAN & KESAN
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS saran_kesan (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  saran TEXT,
  kesan TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. NOTIFICATION SETTINGS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notification_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  workout_reminder BOOLEAN DEFAULT true,
  reminder_time TIME DEFAULT '08:00',
  step_goal INT DEFAULT 10000,
  UNIQUE(user_id)
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE step_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE saran_kesan ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

-- ── Profiles ─────────────────────────────────────────────────────────────────
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- ── Workout Logs ─────────────────────────────────────────────────────────────
CREATE POLICY "Users can view own workout logs"
  ON workout_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workout logs"
  ON workout_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workout logs"
  ON workout_logs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own workout logs"
  ON workout_logs FOR DELETE
  USING (auth.uid() = user_id);

-- ── Favorite Exercises ───────────────────────────────────────────────────────
CREATE POLICY "Users can view own favorites"
  ON favorite_exercises FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own favorites"
  ON favorite_exercises FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites"
  ON favorite_exercises FOR DELETE
  USING (auth.uid() = user_id);

-- ── Step Logs ────────────────────────────────────────────────────────────────
CREATE POLICY "Users can view own step logs"
  ON step_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own step logs"
  ON step_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own step logs"
  ON step_logs FOR UPDATE
  USING (auth.uid() = user_id);

-- ── Workout Plans ────────────────────────────────────────────────────────────
CREATE POLICY "Users can view own workout plans"
  ON workout_plans FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workout plans"
  ON workout_plans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workout plans"
  ON workout_plans FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own workout plans"
  ON workout_plans FOR DELETE
  USING (auth.uid() = user_id);

-- ── Plan Exercises ───────────────────────────────────────────────────────────
-- Access controlled via workout_plans (user must own the parent plan)
CREATE POLICY "Users can view own plan exercises"
  ON plan_exercises FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM workout_plans
      WHERE workout_plans.id = plan_exercises.plan_id
      AND workout_plans.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own plan exercises"
  ON plan_exercises FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workout_plans
      WHERE workout_plans.id = plan_exercises.plan_id
      AND workout_plans.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own plan exercises"
  ON plan_exercises FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM workout_plans
      WHERE workout_plans.id = plan_exercises.plan_id
      AND workout_plans.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own plan exercises"
  ON plan_exercises FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM workout_plans
      WHERE workout_plans.id = plan_exercises.plan_id
      AND workout_plans.user_id = auth.uid()
    )
  );

-- ── Saran & Kesan ────────────────────────────────────────────────────────────
CREATE POLICY "Users can view own saran kesan"
  ON saran_kesan FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own saran kesan"
  ON saran_kesan FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own saran kesan"
  ON saran_kesan FOR UPDATE
  USING (auth.uid() = user_id);

-- ── Notification Settings ────────────────────────────────────────────────────
CREATE POLICY "Users can view own notification settings"
  ON notification_settings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification settings"
  ON notification_settings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notification settings"
  ON notification_settings FOR UPDATE
  USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER: Auto-create profile on user signup
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if any, then create
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
