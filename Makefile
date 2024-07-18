PROJ = -project SwiftDataTCA.xcodeproj -skipPackagePluginValidation -skipMacroValidation
DEST = -scheme SwiftDataTCA -destination "platform=iOS Simulator,name=iPad mini (6th generation)"

default: test

build: clean
	xcodebuild $(PROJ) build-for-testing $(DEST)

test: build
	xcodebuild $(PROJ) test-without-building $(DEST)

clean:
	xcodebuild clean ${DEST}

.PHONY: build test coverage clean
