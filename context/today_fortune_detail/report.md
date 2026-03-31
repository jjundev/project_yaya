# 오늘의 운세 상세 화면 작업 최종 보고서

## 작업 요약

`FortuneHomeView`에서 오늘의 운세 카드를 탭하면 진입하는 전용 상세 화면(`FortuneDetailView`)을 신규 구현했다. 상세 화면은 영역별(사랑·재물·건강·직장) 심층 해설, AI 개인화 편지, 행운 아이템(숫자·색), 공유 기능을 하나의 ScrollView에서 제공한다. 데이터는 `FortuneViewModel.dailyFortune`을 `@EnvironmentObject`로 재사용하며 별도 API 호출이 없다. 또한 `FortuneContent` 모델에 영역별 해설과 개인화 메시지를 위한 optional 필드 5개를 추가했으며, 기존 JSON 디코딩 하위 호환은 optional 선언으로 보장된다. 최종 QA 결과: **빌드 성공, XCTest 51/51, XCUITest 6/6 — PASS**.

---

## 실수 및 수정 이력

| 항목 | 문제 내용 | 원인 | 수정 방법 |
|------|-----------|------|-----------|
| XCUITest 4건 실패 (1차 QA) | `app.otherElements["fortune.detail.header"]` 등 VStack/HStack 컨테이너를 XCUITest에서 찾지 못함 | SwiftUI VStack/HStack은 기본적으로 접근성 트리에 단일 `otherElement`로 노출되지 않는다. `.accessibilityIdentifier`만 추가하고 `.accessibilityElement(children: .contain)`을 누락했기 때문 | `headerSection`, `scoreDetailCard`(4개), `personalMessageSection`, `luckyItemsSection` 4곳에 `.accessibilityElement(children: .contain)` 추가 → 재작업 후 XCUITest 6/6 전체 통과 |

---

## 기술 결정 배경

| 항목 | 결정 | 배경 및 이유 |
|------|------|-------------|
| 네비게이션 방식 | NavigationLink (push) | `FortuneHomeView`가 이미 `NavigationStack` 안에 있어 `NavigationLink`를 선택하면 iOS 표준 뒤로가기(swipe + 버튼)를 추가 구현 없이 무료로 얻을 수 있다. sheet 방식은 풀스크린 콘텐츠에 어울리지 않아 제외했다 |
| 영역별 해설 데이터 | FortuneContent에 optional 필드 5개 추가 | `detailedAnalysis: String?` 단일 필드를 재사용하면 영역별 파싱 로직이 복잡해진다. optional 필드 추가 방식은 기존 패턴(`energySummary`, `elementInsight`)과 일관성이 있고, JSON 하위 호환도 자동으로 보장된다 |
| 공유 기능 | `ShareLink` (iOS 16+) | 앱 최소 배포 타겟이 iOS 17이므로 `ShareLink`를 바로 사용 가능하다. `UIActivityViewController`를 직접 래핑하는 방식보다 코드가 간결하고 SwiftUI 체인에 자연스럽게 통합된다 |
| 점수 시각화 | `FortuneDetailView` 내 `scoreDots` 로컬 함수 | `FortuneHomeView.scoreItem`이 `private`이므로 외부 호출이 불가하다. 동일한 도트 패턴을 내부 함수로 재구현하여 시각 일관성을 유지하면서 결합도를 낮췄다 |
| 프로젝트 파일 등록 | 불필요 (XcodeGen 자동 포함) | `project.yml`이 `Yaya/` 디렉토리를 glob으로 포함하므로, Swift 파일을 추가하면 `make generate` 없이도 다음 빌드 시 자동 인식된다 |

---

## 특이사항 및 다음 스프린트 권장 사항

- **행운의 방향·시간대 미구현**: spec.md "포함" 항목에 명시되어 있으나 같은 문서 "미포함" 항목에 "데이터 모델 추가 → 별도 스프린트"로도 기재되어 스펙 자체에 모순이 있었다. 이번 스프린트에서는 현재 `FortuneContent`에 존재하는 숫자·색만 구현했다. 다음 스프린트에서 `FortuneContent`에 `luckyDirection`, `luckyTime` 필드 추가 후 UI에 반영 권장.
- **Mock 데이터 단계**: 영역별 해설 및 AI 개인화 편지가 현재 hardcode된 mock 값이다. Supabase Edge Function 또는 AI 서비스 prompt에 해당 필드 생성 로직을 추가해야 실제 서비스에서 활용 가능하다.
- **FortuneContent 하위 호환**: 신규 필드 5개는 모두 `String?`이므로 기존 Supabase 테이블/응답에 해당 키가 없어도 디코딩이 실패하지 않는다.
- **다크 모드 / Dynamic Type / VoiceOver**: QA에서 SKIP 처리. 별도 시각 확인 또는 XCUITest 확장 필요.
- **`.accessibilityElement(children: .contain)` 패턴 내재화**: SwiftUI VStack/HStack에 `accessibilityIdentifier`를 붙일 때는 반드시 쌍으로 추가해야 XCUITest에서 `otherElements`로 조회 가능하다는 점을 팀 가이드라인에 추가 권장.

---

## 회고

### 잘된 점
- **데이터 재사용 설계가 깔끔했다**: `@EnvironmentObject` 하나로 별도 API 호출 없이 상세 화면을 완성했다. ViewModel 오염이 없고 테스트 작성도 간단해졌다.
- **하위 호환 유지**: optional 필드 추가 방식으로 기존 JSON 응답과의 호환성을 자동 보장했다. 신규 필드 테스트(with/without)도 단위 테스트로 명시적으로 검증했다.
- **체크리스트 기반 개발**: checklist.md가 사전에 명확히 작성되어 있어 Generator가 scope creep 없이 정확히 필요한 항목만 구현할 수 있었다.
- **재작업 사이클이 빠르게 완료됐다**: 1차 QA에서 XCUITest 실패 원인을 접근성 트리 문제로 정확히 진단하고, 수정 → 재빌드 → XCUITest 재실행까지 한 사이클에 완료했다.

### 개선할 점
- **SwiftUI 접근성 트리 패턴을 초기 구현에서 누락했다**: VStack/HStack에 `accessibilityIdentifier`를 붙일 때 `.accessibilityElement(children: .contain)`이 필요하다는 점을 초기에 인지하지 못해 재작업이 발생했다. 앞으로 XCUITest를 작성할 때마다 컨테이너 뷰에는 이 수식어를 기본으로 추가하는 습관이 필요하다.
- **spec.md 모순을 더 일찍 발견했어야 했다**: 행운의 방향·시간대 항목이 "포함"과 "미포함" 양쪽에 기재된 모순을 Planner 단계에서 발견했지만, spec.md 원본 수정 없이 plan.md에만 기록했다. 다음부터는 모순 발견 즉시 spec.md를 수정하거나 사용자에게 명시적으로 확인 요청하는 것이 바람직하다.
- **XCUITest 실행이 git diff에 의존하는 구조**: `make test-ui-branch`가 `git diff main...HEAD --diff-filter=A`로 신규 파일을 감지하는데, 파일이 untracked 상태일 때는 탐지되지 않는다. 이번 작업처럼 커밋 전 QA를 진행할 경우 git status를 함께 확인하거나 직접 테스트 클래스를 지정하는 방식으로 보완이 필요하다.
