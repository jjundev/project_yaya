# 06. 구독 결제

## 목적
In-App Purchase를 통해 유료 구독을 관리한다.

## 구독 등급

| 등급 | 월 요금 | Product ID | 주요 기능 |
|------|---------|------------|-----------|
| Free | 0원 | - | 오늘의 운세, 기본 분석, 기초 용어 |
| Basic | 4,900원 | com.yaya.subscription.basic | + 주간 운세, ETF 교육, 복리 계산기 |
| Standard | 9,900원 | com.yaya.subscription.standard | + 월간 운세, 중급 교육, 종목 추천 |
| Premium | 19,000원 | com.yaya.subscription.premium | + 연간 운세, 고급 교육, AI 상담, 포트폴리오 |

## 결제 플로우

### iOS (StoreKit 2)
1. 사용자가 구독 등급 선택
2. StoreKit 2 결제 시트 표시
3. Apple 결제 완료
4. Transaction 검증 (서버)
5. `subscriptions` 테이블 INSERT
6. `users.subscription_tier` 자동 갱신 (DB 트리거)

### 서버 검증
- Supabase Edge Function: `verify-subscription`
- Apple Server Notification v2 수신
- 갱신/취소/만료 자동 처리

## 구독 관리

### 업그레이드/다운그레이드
- Apple이 자동 처리 (비례 배분)
- 서버에서 상태 동기화

### 취소
- Apple 설정에서 자동 갱신 해제
- 현재 결제 기간까지는 이용 가능
- 만료 후 free로 자동 변경 (DB 트리거)

### Grace Period
- 결제 실패 시 Apple의 유예 기간 지원
- 상태: `grace_period`

## 쿠폰 적용
- 쿠폰 보유 시 구독 결제 화면에서 할인 적용 가능
- 쿠폰 1장 = 3,000원 할인
