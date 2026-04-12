# Yaya - iOS App Development Harness

## Project Overview
iOS app "Yaya" 개발을 위한 Claude Code 기반 에이전트 파이프라인 하네스.

## Directory Structure
- `ios/` - iOS 앱 소스코드 루트 (Xcode 프로젝트)
- `protocols/` - 개발 규약 (구현 방향, 디자인 패턴, 테스트, 릴리스)
- `requirements/` - 기능 요구사항 명세
- `ios/wireframes/` - UI 와이어프레임
- `jobs/{feature-name}/` - 기능별 작업 산출물

## Agent Skills (수동 트리거)
- `/spector` - 요구사항 구체화 (사용자 대화 기반)
- `/planner` - 구현 계획 작성
- `/reviewer` - 계획/코드 검토 (코드 수정 금지)
- `/implementor` - 코드 구현 + 테스트
- `/reporter` - 작업 보고서 + 학습 기록
- `/publisher` - PR 생성

## Pipeline Rules
- 파이프라인 시작 시 반드시 최신 main 기준 worktree 생성
- iOS 코드는 반드시 `ios/` 폴더 기준으로 작성
- 리뷰 루프 최대 3회 반복, 초과 시 사용자 에스컬레이션
- main merge는 자동화하지 않음 (PR 생성까지만)
- XCUITest 실행 시 시뮬레이터 실행 전제

## Protocols
- `protocols/protocol_main.md` - 전반적 구현 방향
- `protocols/protocol_design_pattern.md` - 디자인 패턴 규약
- `protocols/protocol_testing.md` - 테스트 규약
- `protocols/protocol_release.md` - 릴리스 규약
