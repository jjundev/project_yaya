# User 데이터 모델

## 테이블: `users`

| 필드 | 타입 | 설명 |
|------|------|------|
| id | UUID (PK) | Supabase Auth uid |
| email | TEXT | 이메일 (선택) |
| phone | TEXT | 전화번호 (선택) |
| nickname | TEXT | 닉네임 |
| gender | TEXT | 성별 ('male' / 'female') |
| birth_date | DATE | 생년월일 (양력) |
| birth_time | TEXT | 태어난 시 ('자시'~'해시', null 허용) |
| is_lunar | BOOLEAN | 음력 여부 (default: false) |
| referral_code | TEXT (UNIQUE) | 본인의 추천 코드 |
| referred_by | UUID (FK → users.id) | 추천인 |
| referral_count | INTEGER | 추천한 사람 수 (default: 0) |
| subscription_tier | TEXT | 구독 등급 ('free' / 'basic' / 'standard' / 'premium' / 'vip') |
| created_at | TIMESTAMPTZ | 가입일 |
| updated_at | TIMESTAMPTZ | 수정일 |

## 구독 등급

| 등급 | 월 요금 | 설명 |
|------|---------|------|
| free | 0원 | 기본 사주, 오늘의 운세 |
| basic | 4,900원 | + 6개월 운세, 투자 성향 분석 |
| standard | 9,900원 | + 주식 교육 콘텐츠, 모의투자 |
| premium | 19,000원 | + 종목 추천, 심화 분석 |
| vip | 100만원/년 | + 1:1 맞춤 분석, 전체 기능 |

## 비즈니스 규칙
- 앱 설치 후 생년월일/시/성별 필수 입력 (온보딩)
- 지인 2명 추천 완료 시 → 일주일 후 첫 상품권(3,000원) 지급
- 이후 매월 1회 상품권 자동 지급 (추천 조건 유지 시)
