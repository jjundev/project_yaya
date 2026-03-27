-- 추천 관계 테이블
CREATE TABLE IF NOT EXISTS public.referrals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,  -- 추천한 사람
    referee_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,   -- 추천받은 사람
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed')),
    created_at TIMESTAMPTZ DEFAULT now(),

    -- 동일 추천 중복 방지
    UNIQUE(referrer_id, referee_id)
);

CREATE INDEX idx_referrals_referrer ON public.referrals(referrer_id);
CREATE INDEX idx_referrals_referee ON public.referrals(referee_id);

-- RLS
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own referrals"
    ON public.referrals FOR SELECT
    USING (auth.uid() = referrer_id OR auth.uid() = referee_id);

CREATE POLICY "Users can insert referrals"
    ON public.referrals FOR INSERT
    WITH CHECK (auth.uid() = referee_id);

-- 쿠폰 테이블
CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    amount_won INTEGER NOT NULL DEFAULT 3000,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'used', 'expired')),
    issued_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,

    CONSTRAINT valid_expiry CHECK (expires_at > issued_at)
);

CREATE INDEX idx_coupons_user ON public.coupons(user_id);
CREATE INDEX idx_coupons_status ON public.coupons(status);
CREATE INDEX idx_coupons_expires ON public.coupons(expires_at);

-- RLS
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own coupons"
    ON public.coupons FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own coupons"
    ON public.coupons FOR UPDATE
    USING (auth.uid() = user_id);

-- 추천 확인 시 referral_count 자동 증가 트리거
CREATE OR REPLACE FUNCTION increment_referral_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'confirmed' AND OLD.status = 'pending' THEN
        UPDATE public.users
        SET referral_count = referral_count + 1
        WHERE id = NEW.referrer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER referral_confirmed_trigger
    AFTER UPDATE ON public.referrals
    FOR EACH ROW
    EXECUTE FUNCTION increment_referral_count();
