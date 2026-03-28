SIMULATOR   := iPhone 17 Pro
SCHEME      := Yaya
PROJECT     := Yaya.xcodeproj
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)

.PHONY: generate build run boot-sim test test-unit test-ui test-quick clean

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

# 빌드 없이 유닛 테스트 — 이미 빌드된 상태에서 가장 빠름
test-quick:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		-only-testing:YayaTests \
		test-without-building

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
