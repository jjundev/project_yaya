# 투자 성향 로딩 UX 개선 구현 계획

## 구현 범위
spec.md 기준으로 이번에 구현할 항목:
- `InvestmentOnboardingView`에 `isLoading`, `errorMessage` 파라미터 추가
- `emptyView`를 로딩 중 / 오류 / 기본(nil) 3-상태로 분기
- 세 가지 상태 모두에서 "투자 시작하기" 버튼 즉시 노출
- 호출부(`OnboardingFlowView`, `#Preview`)에 새 파라미터 전달

포함하지 않는 항목 (이유 명시):
- 재시도(retry) 버튼: spec에서 미포함으로 명시
- 백그라운드 재시도 로직: spec에서 미포함으로 명시
- 메인 화면 fallback UX: spec에서 미포함으로 명시

## 기술 결정
| 항목 | 결정 | 이유 |
|------|------|------|
| 상태 전달 방식 | `let isLoading: Bool`, `let errorMessage: String?` 파라미터 추가 | `@ObservedObject`로 ViewModel 자체를 주입하면 뷰 결합도가 높아짐. 값 전달이 테스트·Preview에 유리 |
| 로딩 인디케이터 | `ProgressView()` (SwiftUI 기본) | 추가 라이브러리 불필요, 기존 앱 스타일과 일관 |
| 오류 텍스트 | "아직 투자 성향을 불러오지 못했어요" | 기술 에러 메시지 대신 사용자 친화적 표현 (spec UX 원칙) |
| 버튼 노출 시점 | `emptyView`의 모든 분기에서 `onAppear { showButton = true }` 유지 | 기존 동작 보존, 어떤 상태에서든 진행 가능 |

## 파일 변경 목록
### 신규 생성
- 없음

### 수정
- `ios/Yaya/Yaya/Views/Onboarding/InvestmentOnboardingView.swift` — 파라미터 추가, emptyView 3-상태 분기
- `ios/Yaya/Yaya/Views/Onboarding/OnboardingFlowView.swift` — 호출부에 `isLoading`, `errorMessage` 전달

### 테스트
- `ios/Yaya/YayaTests/InvestmentOnboardingTests.swift` — 로딩/오류 상태 테스트 추가

## 구현 순서
1. `InvestmentOnboardingView`에 `isLoading: Bool`, `errorMessage: String?` 파라미터 추가
2. `emptyView`를 `loadingView` / `errorView` / `fallbackView`로 3-분기
   - `isLoading == true` → `ProgressView` + "투자 성향을 분석하는 중이에요" + `onAppear { showButton = true }`
   - `errorMessage != nil` → 📊 + "아직 투자 성향을 불러오지 못했어요" + "메인 화면에서 확인할 수 있어요" + `onAppear { showButton = true }`
   - 그 외(nil, 미실행) → 📊 + "투자 성향을 불러오는 중이에요" + "메인 화면에서 확인할 수 있어요" + `onAppear { showButton = true }`
3. `OnboardingFlowView`의 `InvestmentOnboardingView` 호출부에 `isLoading: investmentVM.isLoading`, `errorMessage: investmentVM.errorMessage` 추가
4. `#Preview` 블록에 `isLoading: false`, `errorMessage: nil` 기본값 추가
5. `InvestmentOnboardingTests`에 새 테스트 케이스 추가
6. 빌드 및 테스트 실행

## 자체 점검 결과
- 빌드: 성공
- 단위 테스트: 18건 중 18건 통과 (기존 14건 + 신규 4건)
- Product Depth: PASS — isLoading/errorMessage 파라미터 추가, loadingView에 ProgressView, errorView에 사용자 친화 메시지, 기존 순차 애니메이션 유지
- Functionality: PASS — 세 분기 모두 onAppear에서 showButton=true 설정, 버튼 항상 노출, onFinish 콜백 체인 유지

## 특이사항
- `InvestmentViewModel.loadInvestmentProfile`은 현재 mock 데이터를 사용 중 (`// TODO: 실제 AI 분석으로 교체 예정`). Supabase `saveInvestmentProfile`이 실패하면 `catch` 블록에서 `errorMessage`가 설정되므로, 이번 수정으로 해당 오류가 UI에 노출됨.
- UITest 모드의 `UITestInvestmentAnalyzer`는 `OnboardingInvestmentAnalyzing` 프로토콜을 통해 동작하므로, `InvestmentOnboardingView` 파라미터 변경과 무관하게 빌드에 영향 없음. 다만 `OnboardingFlowView`의 호출부가 변경되므로 UITest 흐름도 자동으로 새 파라미터를 사용함.
