# 투자 성향 mock 우선 로딩 구현 계획

## 구현 범위

spec.md 기준으로 이번에 구현할 항목:
- Supabase 캐시 확인 실패가 전체 플로우를 중단하지 않도록 변경
- 기존 에러/로딩/fallback UI는 그대로 유지

포함하지 않는 항목 (이유 명시):
- Supabase 테이블/RLS 설정: Supabase 미준비 상태이므로 이번 스프린트 범위 외
- AI 분석 실제 연동: Edge Function 미배포 상태이므로 이번 스프린트 범위 외

## 기술 결정

| 항목 | 결정 | 이유 |
|------|------|------|
| 캐시 실패 처리 | `try? await supabase.getInvestmentProfile(...)` | 캐시 조회 실패를 nil로 처리하여 다음 단계(mock 분석)로 폴스루. catch 블록으로 전파되지 않음 |
| 에러/fallback UI | 변경 없이 유지 | Supabase 연동 시 필요하며, AI 분석 자체가 실패한 경우 에러 화면이 올바르게 표시되어야 함 |

## 파일 변경 목록

### 수정
- `ios/Yaya/Yaya/ViewModels/InvestmentViewModel.swift` — line 23: `try await` → `try? await`

### 테스트
- `ios/Yaya/YayaTests/InvestmentOnboardingTests.swift` — 캐시 실패 → mock 폴스루 상태 검증 케이스 추가

## 구현 순서

1. `InvestmentViewModel.swift` line 23 수정: `try await` → `try? await`
2. `InvestmentOnboardingTests.swift`에 캐시 실패 시 errorMessage가 설정되지 않는 상태 검증 테스트 추가
3. 빌드 실행 및 성공 확인 (`make build`)
4. 단위 테스트 실행 (`make test-unit` 또는 `make test-quick`)
5. checklist.md 자체 점검 결과 기록

## 핵심 변경 상세

**`ios/Yaya/Yaya/ViewModels/InvestmentViewModel.swift` line 22-26:**

변경 전:
```swift
// 캐시된 프로필 확인
if let cached = try await supabase.getInvestmentProfile(userId: userId) {
    investmentProfile = cached
    return
}
```

변경 후:
```swift
// 캐시된 프로필 확인 (Supabase 미준비 시 캐시 miss로 처리하여 분석 진행)
if let cached = try? await supabase.getInvestmentProfile(userId: userId) {
    investmentProfile = cached
    return
}
```

## 자체 점검 결과
> 구현 완료 후 채웁니다.

- 빌드: 성공
- XCTest(단위 테스트): 44건 중 44건 통과
- Product Depth: PASS — `try?`로 Supabase 실패 시 mock 분석으로 폴스루 확인
- Functionality: PASS — 캐시 실패 → AI 분석 → 프로필 표시 코드 경로 확인

## 특이사항
없음
