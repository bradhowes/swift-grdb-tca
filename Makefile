PROJ = -project SwiftDataTCA.xcodeproj -skipPackagePluginValidation -skipMacroValidation -enableCodeCoverage YES
OUT = -derivedDataPath "$(PWD)/.DerivedData-iOS"
DEST = -scheme SwiftDataTCA -destination "platform=iOS Simulator,name=iPad mini (6th generation)"
QUIET = -quiet -skipMacroValidation
TEST = -testPlan SwiftDataTCA -only-test-configuration Sanitizing
XCCOV = xcrun xccov view --report --only-targets

default: percentage

percentage: coverage
	awk '/ SwiftDataTCA.app / { print $$4 }' coverage.txt > percentage.txt
	cat percentage.txt
	@if [[ -n "$$GITHUB_ENV" ]]; then \
        echo "PERCENTAGE=$$(< percentage.txt)" >> $$GITHUB_ENV; \
    fi

coverage: test
	$(XCCOV) $(PWD)/.DerivedData-iOS/Logs/Test/*.xcresult > coverage.txt
	cat coverage.txt

test: build
	xcodebuild $(QUIET) $(PROJ) $(OUT) test-without-building $(DEST) $(TEST)

build: clean
	xcodebuild $(QUIET) $(PROJ) $(OUT) build-for-testing $(DEST)

clean:
	xcodebuild $(QUIET) clean ${DEST}
	rm -rf "$(PWD)/.DerivedData-iOS"

.PHONY: build test coverage clean
