# iOS Design Pattern

## UI
- SwiftUI 컴포넌트는 역할 단위로 분리한다.
- 재사용 가능한 뷰는 독립 파일로 추출한다.

## ViewModel
- 입력(Action)과 출력(State)을 명시한다.
- 비동기 결과는 상태 전이로 표현한다 (`loading`/`success`/`error`).

## 의존성
- 서비스/리포지토리는 프로토콜 기반 주입을 우선한다.
- 테스트에서 대체 가능한 형태(Fake/Mock)로 설계한다.
