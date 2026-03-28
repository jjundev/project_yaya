SIMULATOR := iPhone 17 Pro
SCHEME     := Yaya
PROJECT    := Yaya.xcodeproj
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR)

.PHONY: generate build run test clean

generate:
	xcodegen generate

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' build

run:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' build
	xcrun simctl boot '$(SIMULATOR)' 2>/dev/null || true
	open -a Simulator

test:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' test

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
