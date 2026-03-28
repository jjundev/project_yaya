# 투자 정체성 온보딩 화면 구현 계획

## 구현 범위

spec.md 기준으로 이번에 구현할 항목:
- InvestmentOnboardingView 신규 생성 (히어로 / sajuBasis / ETF 목록 / 강점 / 리스크 / CTA)
- OnboardingFlowView 플로우 수정 (FirstFortuneResultView.onFinish → InvestmentOnboardingView 경유)
- 섹션별 순차 페이드인 + 슬라이드업 애니메이션
- InvestmentProfile nil 안전 처리
- 단위 테스트 (YayaTests 타겟)

포함하지 않는 항목 (이유 명시):
- 복리 계산기: InvestmentProfileView에서 제공. 이 화면 범위 외
- ETF 상세/링크: 스펙 미포함
- 구독 유도: 스펙 미포함

## 기술 결정

| 항목 | 결정 | 이유 |
|------|------|------|
| 타입별 색상 | InvestmentOnboardingView 내부 switch | 색상은 UI 관심사. 모델 수정 불필요 |
| 애니메이션 | 기존 FadeSlideIn 패턴 재사용 | FirstFortuneResultView와 동일한 패턴 |
| 상태 연결 | showInvestmentOnboarding @State 추가 | 기존 showResult 패턴과 대칭 |
| ETF 소스 | profile.recommendedETFs 우선, nil 시 type.recommendedETFs | 실제 AI 분석 데이터 우선 |

## 파일 변경 목록

### 신규 생성
- `ios/Yaya/Yaya/Views/Onboarding/InvestmentOnboardingView.swift` — 투자 정체성 온보딩 화면
- `ios/Yaya/YayaTests/InvestmentOnboardingTests.swift` — 단위 테스트

### 수정
- `ios/Yaya/Yaya/Views/Onboarding/OnboardingFlowView.swift` — showInvestmentOnboarding 상태 추가, onFinish 콜백 체인 변경

## 구현 순서

1. plan.md 작성 (현재)
2. InvestmentOnboardingView.swift 생성
3. OnboardingFlowView.swift 수정
4. YayaTests 디렉토리 생성 + InvestmentOnboardingTests.swift 작성
5. 빌드 확인
6. checklist.md 자체 점검 결과 업데이트

## 자체 점검 결과

- 빌드: 성공 (Debug-iphonesimulator, iPhone 17)
- 단위 테스트: 11건 중 11건 통과
- Product Depth: PASS — 모든 섹션 InvestmentProfile 필드 직접 사용, 하드코딩 없음
- Functionality: PASS — showInvestmentOnboarding 플로우 체인 코드 검토 완료

## 특이사항
- FadeSlideIn modifier가 FirstFortuneResultView.swift에 private으로 선언됨 → InvestmentOnboardingView에 FadeSlideInInvestment로 재선언
- project.yml에 GoogleSignIn(9.1.0), KakaoSDK(2.27.2) 패키지 및 YayaTests GENERATE_INFOPLIST_FILE 추가 (기존 xcodeproj에만 있던 의존성 명시화)
