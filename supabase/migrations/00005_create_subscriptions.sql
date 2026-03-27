-- 구독 관리 테이블
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    tier TEXT NOT NULL CHECK (tier IN ('basic', 'standard', 'premium')),
    platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
    product_id TEXT NOT NULL,                          -- 앱스토어/플레이스토어 상품 ID
    transaction_id TEXT,                                -- 결제 트랜잭션 ID
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'canceled', 'expired', 'grace_period')),
    started_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL,
    canceled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON public.subscriptions(status);
CREATE INDEX idx_subscriptions_expires ON public.subscriptions(expires_at);

-- RLS
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscriptions"
    ON public.subscriptions FOR SELECT
    USING (auth.uid() = user_id);

-- updated_at 자동 갱신
CREATE TRIGGER subscriptions_updated_at
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- 구독 상태 변경 시 users.subscription_tier 자동 갱신
CREATE OR REPLACE FUNCTION sync_user_subscription_tier()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'active' THEN
        UPDATE public.users
        SET subscription_tier = NEW.tier
        WHERE id = NEW.user_id;
    ELSIF NEW.status IN ('canceled', 'expired') THEN
        -- 다른 활성 구독이 없으면 free로 변경
        IF NOT EXISTS (
            SELECT 1 FROM public.subscriptions
            WHERE user_id = NEW.user_id
              AND id != NEW.id
              AND status = 'active'
        ) THEN
            UPDATE public.users
            SET subscription_tier = 'free'
            WHERE id = NEW.user_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subscription_tier_sync
    AFTER INSERT OR UPDATE ON public.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION sync_user_subscription_tier();
