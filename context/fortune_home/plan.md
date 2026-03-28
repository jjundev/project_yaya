# 메인 홈 화면 구현 계획

## 구현 범위
spec.md 기준으로 이번에 구현할 항목:
- 개인화 헤더 (날짜 + 에너지 한 줄)
- 오늘의 운세 카드 (기존 유지 + 개선)
- 오행 에너지 인사이트 카드 (기존 사주 요약 카드 고도화)
- 주간 운세 블러 미리보기 (기존 잠금 카드 교체)
- AI 사주 상담 CTA 배너
- Pull-to-refresh (기존 유지)
- 에러 시 재시도 버튼
- 자정 날짜 체크 (날짜 변경 감지)

포함하지 않는 항목 (이유 명시):
- 투자 에너지 섹션: 별도 탭으로 분리 결정
- 월간/연간 블러 미리보기: 다음 스프린트
- 소셜 공유: 다음 스프린트

## 기술 결정

| 항목 | 결정 | 이유 |
|------|------|------|
| 에너지 한 줄 데이터 | `FortuneContent`에 `energySummary` 필드 추가 | AI가 운세 생성 시 함께 생성. Edge Function 미배포 상태이므로 mock에 추가 |
| 오행 인사이트 문구 | `FortuneContent`에 `elementInsight` 필드 추가 | 오늘 기운과 사주 오행의 관계를 AI가 생성 |
| 주간 운세 블러 | `.blur()` modifier + overlay | SwiftUI 기본 제공, 추가 라이브러리 불필요 |
| 구독 등급 확인 | 기존 `SubscriptionTier` 비교 연산 | 기존 모델 그대로 활용 |
| 날짜 변경 감지 | `scenePhase` + 날짜 비교 | foreground 복귀 시 날짜가 바뀌었으면 새 운세 로드 |
| 테스트 타겟 | `YayaTests` 디렉토리 신규 생성 | project.yml에 이미 타겟 정의됨, 소스 디렉토리만 없는 상태 |

## 파일 변경 목록

### 신규 생성
- `ios/Yaya/YayaTests/FortuneHomeViewModelTests.swift` — FortuneViewModel 단위 테스트

### 수정
- `ios/Yaya/Yaya/Models/Fortune.swift` — `FortuneContent`에 `energySummary`, `elementInsight` 필드 추가
- `ios/Yaya/Yaya/Views/Fortune/FortuneHomeView.swift` — 전체 리팩토링 (헤더, 블러, CTA, 재시도, 날짜 감지)
- `ios/Yaya/Yaya/ViewModels/FortuneViewModel.swift` — 주간 운세 로드 함수 추가, 날짜 변경 감지 로직
- `ios/Yaya/Yaya/Services/AIService.swift` — mock 데이터에 `energySummary`, `elementInsight` 추가

### 테스트
- `ios/Yaya/YayaTests/FortuneHomeViewModelTests.swift` — FortuneViewModel 로직 테스트

## 구현 순서
1. `FortuneContent` 모델 확장 (`energySummary`, `elementInsight` 추가)
2. `AIService` mock 데이터 업데이트
3. `FortuneViewModel` 확장 (주간 운세 로드, 날짜 변경 체크)
4. `FortuneHomeView` 전면 리팩토링
   - 개인화 헤더 섹션
   - 오늘의 운세 카드 (기존 유지 + 재시도 버튼 추가)
   - 오행 에너지 인사이트 카드 (인사이트 문구 + 바 차트)
   - 주간 운세 블러 미리보기 카드
   - AI 상담 CTA 배너
   - 날짜 변경 감지 (scenePhase)
5. 빌드 확인
6. 단위 테스트 작성 및 실행
7. checklist.md 자체 점검

## 자체 점검 결과

- 빌드: 성공 (warning 없음)
- 단위 테스트: 12건 중 12건 통과
- Product Depth: PASS — 스펙의 모든 필수 UI 요소 구현 완료
- Functionality: PASS — 로드/리프레시/에러 재시도/날짜 감지 모두 구현

## 특이사항
- Edge Function 미배포 상태이므로 모든 데이터는 AIService mock으로 동작
- `energySummary`와 `elementInsight`는 optional로 추가하여 기존 API 응답과 호환 유지
- 주간 운세도 mock 데이터로 구현 (실제 AI 생성은 Edge Function 배포 후)
- `project.yml`은 변경하지 않고 `pbxproj`에 직접 테스트 타겟 설정 추가 (기존 SPM 패키지 보존)

### 재작업 (qa.md FAIL 수정)
- 구독하기/AI CTA 버튼 탭 시 `.sheet` 기반 구독 안내 Sheet 표시로 수정
- `@State showSubscriptionSheet` + `subscriptionPromptTier`로 Basic/Premium 분기
- Sheet에 구독 등급명, 월 가격, 기능 목록 표시 (기존 `SubscriptionTier` 활용)
- 실제 인앱 구매 연동은 `// TODO`로 남김 (구독 기능 스프린트에서 구현)
