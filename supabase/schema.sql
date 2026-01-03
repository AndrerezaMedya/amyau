-- ================================================
-- SUPABASE DATABASE SCHEMA
-- Mutabaah Yaumi - Tracking Ibadah Harian
-- ================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================
-- 1. USERS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL UNIQUE,
    full_name TEXT,
    gender CHAR(1) CHECK (gender IN ('L', 'P')), -- L = Laki-laki, P = Perempuan
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policy for users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Allow users to insert their own profile during signup
CREATE POLICY "Users can create own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- ================================================
-- 2. ACTIVITIES TABLE (Reference table - 12 aktivitas)
-- Evaluation Period:
--   - daily: ≥50% hari/bulan = V
--   - weekly: ≥threshold/minggu = V  
--   - monthly: ≥threshold/bulan = V
-- ================================================
CREATE TABLE IF NOT EXISTS public.activities (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    target TEXT NOT NULL,
    jenis TEXT NOT NULL CHECK (jenis IN ('individu', 'grupBpc')),
    evaluation_period TEXT NOT NULL CHECK (evaluation_period IN ('daily', 'weekly', 'monthly')),
    threshold INTEGER NOT NULL DEFAULT 1, -- Minimal count for V
    keterangan TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert 12 aktivitas sesuai tabel
INSERT INTO public.activities (id, name, target, jenis, evaluation_period, threshold, keterangan) VALUES
-- DAILY: ≥50% hari/bulan
(1, 'Membaca Al-Qur''an', '1 juz/hari', 'individu', 'daily', 1, ''),
(2, 'Membaca Wadzifah Sugro (Al Ma''tsurat)', 'Pagi atau Petang', 'individu', 'daily', 1, 'Wadzifah sugra setiap hari'),
(3, 'Tahajud', 'Setiap hari', 'individu', 'daily', 1, ''),
(5, 'Memperbanyak Istighfar', 'Setiap hari', 'individu', 'daily', 1, ''),
(6, 'Memperbanyak Sholawat Nabi', 'Setiap hari', 'individu', 'daily', 1, ''),
(7, 'Mendoakan kebaikan (anggota mentoring, pemimpin, bangsa, umat Islam)', 'Setiap hari', 'individu', 'daily', 1, ''),
(8, 'Shalat berjamaah di masjid', '3 kali/hari', 'individu', 'daily', 1, ''),
(10, 'Infaq mingguan', 'Setiap anggota', 'individu', 'daily', 1, ''),
-- MONTHLY: ≥threshold/bulan  
(4, 'Puasa Sunnah (Ayyamul Bidh / Senin-Kamis)', '≥3 hari/bulan', 'individu', 'monthly', 3, ''),
(9, 'Meluangkan & mempersiapkan waktu terbaik utk pertemuan pekanan', '≥2 kali/bulan', 'individu', 'monthly', 2, ''),
(12, 'Mengikuti MABIT (Malam Pembinaan Iman & Taqwa)', '≥1 kali/bulan', 'grupBpc', 'monthly', 1, 'Kegiatan: buka puasa/sahur bersama, sholat tahajud dll'),
-- WEEKLY: ≥threshold/minggu
(11, 'Membaca artikel / menonton video dakwah', '≥1 kali/minggu', 'individu', 'weekly', 1, '')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    target = EXCLUDED.target,
    jenis = EXCLUDED.jenis,
    evaluation_period = EXCLUDED.evaluation_period,
    threshold = EXCLUDED.threshold,
    keterangan = EXCLUDED.keterangan;

-- RLS Policy for activities (read-only for all authenticated users)
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Activities are viewable by authenticated users" ON public.activities
    FOR SELECT TO authenticated USING (true);

-- ================================================
-- 3. DAILY_LOGS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS public.daily_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    activity_id INTEGER NOT NULL REFERENCES public.activities(id),
    date DATE NOT NULL,
    value INTEGER NOT NULL DEFAULT 0, -- 0-100 for percentage, 0/1 for binary
    status CHAR(1) NOT NULL CHECK (status IN ('V', 'X')), -- V = tercapai, X = belum
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint: one log per user per activity per day
    UNIQUE(user_id, activity_id, date)
);

-- Index for faster queries
CREATE INDEX idx_daily_logs_user_date ON public.daily_logs(user_id, date);
CREATE INDEX idx_daily_logs_date ON public.daily_logs(date);

-- RLS Policy for daily_logs
ALTER TABLE public.daily_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own logs" ON public.daily_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own logs" ON public.daily_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own logs" ON public.daily_logs
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own logs" ON public.daily_logs
    FOR DELETE USING (auth.uid() = user_id);

-- ================================================
-- 4. WEEKLY_SUMMARY TABLE (for AI reviews)
-- ================================================
CREATE TABLE IF NOT EXISTS public.weekly_summary (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    week_end DATE NOT NULL,
    ai_review TEXT NOT NULL,
    total_achieved INTEGER NOT NULL DEFAULT 0,
    total_activities INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX idx_weekly_summary_user ON public.weekly_summary(user_id, week_start);

-- RLS Policy
ALTER TABLE public.weekly_summary ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own summaries" ON public.weekly_summary
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own summaries" ON public.weekly_summary
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ================================================
-- 5. HELPER FUNCTIONS
-- ================================================

-- Function to create user profile after signup (with full_name & gender from metadata)
-- SECURITY DEFINER: Runs with the privileges of the user who created the function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, username, full_name, gender, created_at)
    VALUES (
        NEW.id, 
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        NULLIF(NEW.raw_user_meta_data->>'gender', ''),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING; -- Ignore if already exists
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the signup
        RAISE WARNING 'Failed to create user profile for %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create user profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to calculate weekly stats
CREATE OR REPLACE FUNCTION get_weekly_stats(p_user_id UUID, p_week_start DATE)
RETURNS TABLE (
    activity_id INTEGER,
    activity_name TEXT,
    achieved_days INTEGER,
    total_days INTEGER,
    achievement_percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.name,
        COALESCE(SUM(CASE WHEN dl.status = 'V' THEN 1 ELSE 0 END)::INTEGER, 0) as achieved_days,
        7 as total_days,
        COALESCE(ROUND(SUM(CASE WHEN dl.status = 'V' THEN 1 ELSE 0 END)::NUMERIC / 7 * 100, 2), 0) as achievement_percentage
    FROM public.activities a
    LEFT JOIN public.daily_logs dl ON a.id = dl.activity_id 
        AND dl.user_id = p_user_id
        AND dl.date >= p_week_start 
        AND dl.date < p_week_start + INTERVAL '7 days'
    GROUP BY a.id, a.name
    ORDER BY a.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 6. SAMPLE DATA (Optional - for testing)
-- ================================================
-- Uncomment to insert sample users after they sign up via Auth

-- To add a user manually (after they exist in auth.users):
-- INSERT INTO public.users (id, username, full_name, gender)
-- VALUES ('user-uuid-here', 'username@email.com', 'Nama Lengkap', 'L');
