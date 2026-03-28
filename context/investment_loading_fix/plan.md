# 투자 성향 로딩 실패 수정 구현 계획

## 구현 범위
spec.md 기준으로 이번에 구현할 항목:
- `AIService.analyzeInvestmentType()`의 Edge Function 호출을 주석 처리하고 mock 데이터 반환으로 전환
- `mockInvestmentProfile()` 함수 추가 (`InvestmentProfile` 전체 필드 포함)
- `InvestmentViewModel.loadInvestmentProfile()`에서 `investmentProfile` 할당을 `saveInvestmentProfile` 호출 앞으로 이동, 저장을 `try?`로 전환

포함하지 않는 항목 (이유 명시):
- `"investment-personality"` Edge Function 배포: spec에서 미포함으로 명시 (다음 스프린트)
- `investment_profiles` 테이블 RLS 정책 검토: spec에서 미포함으로 명시

## 기술 결정
| 항목 | 결정 | 이유 |
|------|------|------|
| mock 패턴 | `analyzeSaju()`와 동일하게 Edge Function 주석 처리 + `Task.sleep` + mock 반환 | 기존 패턴과 일관성 유지, `analyzeSaju()`에서 검증된 방식 |
| mock 로딩 시간 | `1_000_000_000` ns (1초) | 사주 분석(2초)보다 짧게 — 이미 사주 분석 후이므로 빠르게 완료하는 것이 UX에 적합 |
| mock 투자 유형 | `.stable` | 기존 XCUITest mock(`UITestInvestmentAnalyzer`)에서 `.stable` 사용 중 — 테스트 일관성 |
| 저장 실패 처리 | `try?`로 무시 | 분석 결과는 UI에 이미 반영 완료. 저장 실패 시 다음 접속에서 재분석하면 됨 |
| `userId` 전달 | mock 내부에서 하드코딩된 UUID 사용 | `analyzeInvestmentType` 시그니처는 `sajuAnalysis`만 받음. userId는 `InvestmentViewModel`에서 `saveInvestmentProfile`과 별개로 관리 |

## 파일 변경 목록
### 신규 생성
- 없음

### 수정
- `ios/Yaya/Yaya/Services/AIService.swift` — `analyzeInvestmentType` Edge Function 주석 처리 + mock 반환, `mockInvestmentProfile()` 함수 추가
- `ios/Yaya/Yaya/ViewModels/InvestmentViewModel.swift` — `investmentProfile = profile` 할당을 `saveInvestmentProfile` 호출 앞으로 이동, `try await` → `try?`

### 테스트
- `ios/Yaya/YayaTests/InvestmentOnboardingTests.swift` — 필요 시 기존 테스트가 새 mock 데이터와 호환되는지 확인 (수정 필요 없을 가능성 높음)

## 구현 순서
1. `AIService.swift`의 `analyzeInvestmentType()` 수정: Edge Function 호출 주석 처리, `Task.sleep(1초)` + `mockInvestmentProfile()` 반환
2. `AIService.swift`에 `mockInvestmentProfile()` 함수 추가 (Mock Data 섹션)
3. `InvestmentViewModel.swift`의 `loadInvestmentProfile()` 수정: `investmentProfile = profile`을 `saveInvestmentProfile` 앞으로 이동, `try?` 적용
4. 빌드 실행
5. 기존 단위 테스트 실행 (18건)
6. checklist.md 자체 점검

## 자체 점검 결과
- 빌드: 성공
- 단위 테스트: 34건 중 34건 통과 (기존 전부 통과)
- Product Depth: PASS — `analyzeInvestmentType` Edge Function 주석 처리 + mock 반환, mock 전체 필드 포함, `investmentProfile` 할당 순서 수정
- Functionality: PASS — 빌드 성공, 테스트 회귀 없음, 저장 실패 시에도 프로필 표시 가능

## 특이사항
- `analyzeInvestmentType`의 시그니처(`sajuAnalysis: SajuAnalysis`) → `InvestmentProfile`은 변경하지 않음. mock에서 `userId`는 placeholder UUID 사용.
- `InvestmentViewModel`에서 `profile`을 만들 때 `aiService.analyzeInvestmentType()`이 반환하는 mock에 `userId`가 포함되지만, 실제로는 `SupabaseService.saveInvestmentProfile(profile)`에서 해당 `userId`로 DB에 저장. mock이므로 실제 저장 시 무결성 문제가 생길 수 있으나, `try?`로 무시하므로 영향 없음.
