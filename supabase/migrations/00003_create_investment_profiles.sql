-- 투자 성향 분석 결과 테이블
CREATE TABLE IF NOT EXISTS public.investment_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    investment_type TEXT NOT NULL CHECK (investment_type IN ('aggressive', 'stable', 'value', 'growth')),
    description TEXT NOT NULL,
    strengths TEXT[] NOT NULL DEFAULT '{}',
    risks TEXT[] NOT NULL DEFAULT '{}',
    recommended_etfs TEXT[] NOT NULL DEFAULT '{}',
    saju_basis TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    -- 사용자당 하나의 투자 프로필
    UNIQUE(user_id)
);

-- RLS 활성화
ALTER TABLE public.investment_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own investment profile"
    ON public.investment_profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own investment profile"
    ON public.investment_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own investment profile"
    ON public.investment_profiles FOR UPDATE
    USING (auth.uid() = user_id);

-- updated_at 자동 갱신
CREATE TRIGGER investment_profiles_updated_at
    BEFORE UPDATE ON public.investment_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
