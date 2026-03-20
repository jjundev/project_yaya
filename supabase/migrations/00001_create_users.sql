-- 사용자 프로필 테이블
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    phone TEXT,
    nickname TEXT,
    gender TEXT CHECK (gender IN ('male', 'female')),
    birth_date DATE NOT NULL,
    birth_time TEXT, -- 12시진: 자시~해시, null = 모름
    is_lunar BOOLEAN DEFAULT false,
    referral_code TEXT UNIQUE DEFAULT gen_random_uuid()::text,
    referred_by UUID REFERENCES public.users(id),
    referral_count INTEGER DEFAULT 0,
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'basic', 'standard', 'premium', 'vip')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS 활성화
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 본인 데이터만 조회/수정 가능
CREATE POLICY "Users can view own profile"
    ON public.users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 추천 코드 검색용 (타인 코드 조회 허용)
CREATE POLICY "Anyone can lookup referral codes"
    ON public.users FOR SELECT
    USING (true);

-- updated_at 자동 갱신 트리거
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
