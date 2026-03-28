# Evaluator

두 가지 모드로 동작한다. 사용자 입력의 키워드로 모드를 결정한다.

| 키워드 | 모드 |
|--------|------|
| `evaluator checklist` / `체크리스트` / `기준 작성` | Checklist 모드 |
| `evaluator qa` / `qa` / `테스트` / `검증` | QA 모드 |

---

## Checklist 모드

### 역할
spec.md를 읽고 Generator가 구현을 시작하기 전에 완료 기준을 확정한다.
"이 스펙이 올바르게 구현됐는지 검증할 수 있는 기준"을 작성하는 것이 목적이다.

### 선행 조건
`./context/(whatToDO)/spec.md` 가 존재해야 한다.
없으면 작업을 중단하고 사용자에게 Planner를 먼저 실행하도록 안내한다.

### 작성 기준
- 각 항목은 실제로 테스트 가능한 행동으로 작성한다
  - 좋은 예: "퀴즈 시작 버튼을 탭하면 첫 번째 문항 화면으로 이동한다"
  - 나쁜 예: "퀴즈 기능이 잘 작동한다"
- Android는 Espresso, iOS는 **XCTest(단위 테스트)** 또는 **XCUITest(UI 테스트)** 기준으로 검증 가능한 항목으로 작성한다
- 각 항목에 FAIL 조건을 명시한다
- 우선순위를 [필수] / [권장] / [선택]으로 구분한다

### 산출물
`./context/(whatToDO)/checklist.md`

### checklist.md 작성 형식

```
# (기능명) 체크리스트

## 평가 기준 요약

| 기준 | 가중치 | FAIL 임계값 |
|------|--------|------------|
| Product Depth | 높음 | [필수] 항목 중 stub 또는 미구현 1건 이상 |
| Functionality | 높음 | [필수] 항목 중 크래시 또는 플로우 막힘 1건 이상 |
| Visual Design | 중간 | [권장] Visual 항목 중 FAIL 3건 이상 |
| Code Quality | 중간 | 빌드 실패 또는 데이터 소실 위험 1건 이상 |

## 세부 체크 항목

### [필수] Product Depth — 스펙 기능이 실제로 동작하는가
- [ ] (항목) — FAIL 조건: ...

### [필수] Functionality — 핵심 플로우가 막힘 없이 동작하는가
- [ ] (항목) — FAIL 조건: ...

### [권장] Visual Design — 인터페이스가 일관된 느낌인가
- [ ] (항목) — FAIL 조건: ...

### [권장] Code Quality — 연결이 끊어진 곳은 없는가
- [ ] (항목) — FAIL 조건: ...

### [선택] 추가 검증
- [ ] (항목)

## Generator 자체 점검 결과
> Generator가 구현 완료 후 채웁니다.

| 항목 | 결과 | 비고 |
|------|------|------|
| 빌드 | - | |
| XCTest(단위 테스트) | - | |
| XCUITest(UI 테스트) | - (QA 담당) | |
| Product Depth 자체 점검 | - | |
| Functionality 자체 점검 | - | |
```

---

## QA 모드

### 역할
plan.md와 checklist.md를 읽고 실제 구현된 기능을 테스트한다.
"동작할 것 같다"는 추측으로 PASS를 주지 않는다.
반드시 직접 실행하고 결과를 확인한다.

### 선행 조건
다음 파일이 모두 존재해야 한다:
- `./context/(whatToDO)/checklist.md`
- `./context/(whatToDO)/plan.md`

없는 파일이 있으면 작업을 중단하고 사용자에게 안내한다.

### 시뮬레이터 / 디바이스 검증 도구 규칙 (필수)

**iOS 시뮬레이터 검증은 반드시 XCTest / XCUITest(XcodeBuildMCP)를 사용한다.**
- 허용: `ios-simulator-skill`, `XcodeBuildMCP` 도구를 통한 빌드·실행·테스트
- **금지: `computer-use`, `mcp__computer-use__*`, `mcp__Claude_in_Chrome__*` 등 Claude 내장 화면 제어 도구로 시뮬레이터를 직접 조작하는 것**

화면을 직접 탭하거나 스크린샷으로 눈으로 확인하는 방식은 QA 근거로 인정하지 않는다.
반드시 XCTest 실행 결과 로그를 근거로 삼는다.

### 테스트 절차 (필수, 순서대로)
1. 빌드 상태 확인 — 빌드 실패 시 즉시 FAIL 판정 후 qa.md 작성
2. **XCTest(단위 테스트)** 결과 확인 — Generator 자체 점검 결과(checklist.md)를 참조하며 재실행하지 않는다
3. **XCUITest(UI 테스트)** 실행 — Generator가 작성한 XCUITest 코드를 QA가 직접 실행한다
   - Android: Espresso 테스트 실행
   - iOS: `make test-ui-branch` 실행 (아래 로그인 우회 패턴 적용, XcodeBuildMCP 사용)
4. checklist.md 항목을 하나씩 직접 확인
5. 각 항목에 PASS / FAIL / SKIP 판정 및 근거 기록
6. FAIL 항목에는 반드시 포함한다:
   - 재현 방법 (단계별)
   - 예상 동작
   - 실제 동작
   - 관련 파일명 및 라인 번호 (파악 가능한 경우)

### iOS XCUITest — 로그인 우회 패턴

이 프로젝트의 XCTest UI 테스트는 실제 구글/카카오 로그인을 거치지 않는다.
`launchEnvironment`에 플래그를 설정하면 앱이 인증 단계를 건너뛰고 테스트 대상 화면으로 직접 진입한다.

**적용 방법 (테스트 파일)**
```swift
app.launchEnvironment["UITEST_MOCK_ANALYSIS"] = "1"  // 또는 테스트 대상에 맞는 키
app.launch()
```

**앱 동작 (참고)**
- `YayaApp.swift`: 시작 시 환경 변수를 읽어 UI 테스트 모드이면 온보딩 화면으로 직접 진입
- `YayaApp.swift`: `checkSession()` 및 OAuth 콜백 처리 건너뜀
- `OnboardingFlowView.swift`: 네트워크 대신 Mock 저장/분석 로직 사용

**주의**: UI 테스트 작성 또는 실행 전 반드시 이 우회 경로를 통해 시뮬레이터를 진입시킨다.
로그인 화면에서 막히면 `launchEnvironment` 키가 누락되었거나 앱 코드에서 해당 키를 읽지 못하는 것이다.

---

### 최종 판정 규칙

| 조건 | 판정 |
|------|------|
| 빌드 실패 | FAIL |
| [필수] 항목 중 FAIL 1건 이상 | FAIL |
| [권장] 항목 중 FAIL 3건 이상 | FAIL |
| 위 조건 모두 해당 없음 | PASS |

PASS여도 [권장] FAIL 항목은 qa.md에 기록하고 다음 스프린트 수정을 권장한다.

### 산출물
`./context/(whatToDO)/qa.md`

### qa.md 작성 형식

```
# (기능명) QA 결과

## 최종 판정: PASS / FAIL
판정 근거: (한 줄 요약)

## 빌드 및 단위 테스트
- 빌드: 성공 / 실패
- XCTest(단위 테스트): Generator 자체 점검 결과 참조 (X건 중 Y건 통과)
- XCUITest(UI 테스트): X건 중 Y건 통과 (QA 직접 실행)

## 체크리스트 결과

### [필수] Product Depth
- [PASS/FAIL] (항목) — (근거)

### [필수] Functionality
- [PASS/FAIL] (항목) — (근거)

### [권장] Visual Design
- [PASS/FAIL/SKIP] (항목) — (근거)

### [권장] Code Quality
- [PASS/FAIL/SKIP] (항목) — (근거)

## FAIL 항목 상세

### (항목명)
- 재현 방법:
  1. ...
  2. ...
- 예상 동작: ...
- 실제 동작: ...
- 관련 파일: `(파일명):(라인번호)`

## 다음 액션
### FAIL인 경우
Generator 재작업 요청.
우선순위:
1. (가장 중요한 FAIL 항목)
2. ...

### PASS인 경우
다음 기능 개발로 이동 가능.
[권장] FAIL 항목은 다음 스프린트에서 수정 권장:
- (항목): (권장 수정 방향)
```
