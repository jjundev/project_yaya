SIMULATOR   := iPhone 17 Pro
SCHEME      := Yaya
PROJECT     := Yaya.xcodeproj
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)

.PHONY: generate build run boot-sim test test-unit test-ui test-ui-branch test-quick clean

generate:
	xcodegen generate

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' build

run:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' build
	xcrun simctl boot '$(SIMULATOR)' 2>/dev/null || true
	open -a Simulator

boot-sim:
	xcrun simctl boot '$(SIMULATOR)' 2>/dev/null || true
	open -a Simulator

# 전체 테스트 (유닛 + UI)
test:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' test

# 유닛 테스트만 — 개발 중 반복 실행용
test-unit:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		-only-testing:YayaTests \
		test

# UI 테스트만
test-ui:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		-only-testing:YayaUITests \
		test

# 이번 브랜치에서 추가된 XCUITest만 실행
test-ui-branch:
	@set -e; \
	REPO_ROOT=$$(git -C ../.. rev-parse --show-toplevel); \
	FILES=$$(git -C ../.. diff main...HEAD --name-only --diff-filter=A -- 'ios/Yaya/YayaUITests/*.swift'); \
	if [ -z "$$FILES" ]; then \
		echo "이번 브랜치에서 추가된 XCUITest 파일 없음"; exit 0; \
	fi; \
	ONLY_FLAGS=""; \
	for f in $$FILES; do \
		CLASS=$$(grep -E '^class [A-Za-z0-9_]+' "$$REPO_ROOT/$$f" | head -1 | awk '{print $$2}'); \
		if [ -n "$$CLASS" ]; then \
			ONLY_FLAGS="$$ONLY_FLAGS -only-testing:YayaUITests/$$CLASS"; \
		fi; \
	done; \
	if [ -z "$$ONLY_FLAGS" ]; then \
		echo "클래스명 추출 실패"; exit 1; \
	fi; \
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		$$ONLY_FLAGS \
		test

# 빌드 없이 유닛 테스트 — 이미 빌드된 상태에서 가장 빠름
test-quick:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		-only-testing:YayaTests \
		test-without-building

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
