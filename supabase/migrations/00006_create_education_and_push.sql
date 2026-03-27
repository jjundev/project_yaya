-- 교육 콘텐츠 캐시 테이블
CREATE TABLE IF NOT EXISTS public.education_contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('basic', 'intermediate', 'advanced')),
    investment_type TEXT CHECK (investment_type IN ('aggressive', 'stable', 'value', 'growth')),
    required_tier TEXT NOT NULL DEFAULT 'free' CHECK (required_tier IN ('free', 'basic', 'standard', 'premium')),
    tags TEXT[] DEFAULT '{}',
    is_published BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_education_category ON public.education_contents(category);
CREATE INDEX idx_education_type ON public.education_contents(investment_type);
CREATE INDEX idx_education_tier ON public.education_contents(required_tier);

-- RLS (모든 인증 사용자 읽기 가능, 티어 체크는 앱에서)
ALTER TABLE public.education_contents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view published content"
    ON public.education_contents FOR SELECT
    USING (is_published = true);

-- updated_at 자동 갱신
CREATE TRIGGER education_contents_updated_at
    BEFORE UPDATE ON public.education_contents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- 푸시 알림 토큰 테이블
CREATE TABLE IF NOT EXISTS public.push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    UNIQUE(user_id, token)
);

CREATE INDEX idx_push_tokens_user ON public.push_tokens(user_id);
CREATE INDEX idx_push_tokens_active ON public.push_tokens(is_active) WHERE is_active = true;

-- RLS
ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own push tokens"
    ON public.push_tokens FOR ALL
    USING (auth.uid() = user_id);

-- updated_at 자동 갱신
CREATE TRIGGER push_tokens_updated_at
    BEFORE UPDATE ON public.push_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
