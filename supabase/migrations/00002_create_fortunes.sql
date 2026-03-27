-- 운세 캐시 테이블
-- AI 생성 운세를 날짜별로 캐시하여 재호출 방지
CREATE TABLE IF NOT EXISTS public.fortunes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    fortune_type TEXT NOT NULL CHECK (fortune_type IN ('daily', 'weekly', 'monthly', 'yearly')),
    content JSONB NOT NULL,
    date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),

    -- 동일 사용자, 동일 타입, 동일 날짜 중복 방지
    UNIQUE(user_id, fortune_type, date)
);

-- 인덱스
CREATE INDEX idx_fortunes_user_date ON public.fortunes(user_id, date DESC);
CREATE INDEX idx_fortunes_type ON public.fortunes(fortune_type);

-- RLS 활성화
ALTER TABLE public.fortunes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own fortunes"
    ON public.fortunes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own fortunes"
    ON public.fortunes FOR INSERT
    WITH CHECK (auth.uid() = user_id);
