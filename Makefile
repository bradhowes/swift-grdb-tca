PROJ = -project SwiftDataTCA.xcodeproj -skipPackagePluginValidation -skipMacroValidation
DEST = -scheme SwiftDataTCA -destination "platform=iOS Simulator,name=iPad mini (6th generation)"
QUIET = -quiet

default: test

build: clean
	xcodebuild $(QUIET) $(PROJ) build-for-testing $(DEST)

test: build
	xcodebuild $(QUIET) $(PROJ) test-without-building $(DEST)

clean:
	xcodebuild clean ${DEST}

.PHONY: build test coverage clean
