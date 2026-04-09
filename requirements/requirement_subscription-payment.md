# Requirement: 구독 결제 시스템

## 개요
사용자가 앱 내에서 구독 티어(Basic/Standard/Premium)를 선택하고 정기 결제할 수 있는 인앱 결제 시스템.

## 배경
음성 녹음(260319_155013.m4a)에서 "4,900원 / 9,900원 / 19,000원의 월 구독 상품으로 각기 다른 깊이의 정보를 제공"하고 명시.  
현재 앱에는 `SubscriptionTier` enum만 존재하며, 실제 결제 처리나 구독 상태 관리 로직이 없다.

## 범위

### In Scope
- 구독 티어별 가격 및 혜택 표시 화면
- Apple In-App Purchase (StoreKit 2) 연동
- 구독 상태 서버 동기화 (Supabase)
- 구독 복원 (Restore Purchases) 기능
- 구독 만료/갱신 처리

### Out of Scope
- Android 결제 (Google Play Billing) — 별도 작업
- 쿠폰 할인 적용 로직 (requirement_coupon-referral.md 참조)
- 환불 처리 (Apple이 직접 처리)

## 기능 요구사항

### FR-1. 구독 플랜 화면
- 3개 플랜 카드 표시:
  - Basic: 4,900원/월 — 사주 상세 분석 + 모의투자 기본
  - Standard: 9,900원/월 — Basic + 6개월 운세 + 심화 종목 분석
  - Premium: 19,000원/월 — Standard + VIP 커뮤니티 + 맞춤 포트폴리오
- 현재 구독 티어 하이라이트 표시

### FR-2. 인앱 결제 (StoreKit 2)
- `StoreKit 2` API를 사용해 Apple IAP 처리.
- 결제 완료 시 `Transaction` 검증 후 Supabase에 구독 상태 업데이트.
- 월간 자동 갱신 구독 상품으로 구성.

### FR-3. 구독 상태 동기화
- 앱 시작 시 `StoreKit.currentEntitlements`를 조회해 로컬 `SubscriptionTier` 업데이트.
- Supabase의 `users.subscription_tier` 필드와 동기화.

### FR-4. 구독 복원
- 마이페이지에 "구독 복원" 버튼 제공.
- `AppStore.sync()` 호출 후 entitlement 재조회.

### FR-5. 구독 만료 처리
- 만료된 구독은 Free 티어로 자동 다운그레이드.
- 만료 3일 전 Push Notification 발송 (NotificationManager 활용).

## 비기능 요구사항
- StoreKit 2 사용 (iOS 15+, 기존 StoreKit 1 미사용)
- 결제 영수증 서버 검증 필수 (클라이언트 신뢰 금지)
- Sandbox 환경에서 테스트 후 Production 배포

## Open Questions
- Q1. 연간 구독 상품도 제공할지? (언급 없음)
- Q2. 무료 체험 기간(free trial) 제공 여부?
- Q3. 쿠폰(3,000원)이 구독 결제에서 어떻게 차감되는지 명확화 필요 (coupon-referral requirement와 연계)
