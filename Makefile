PROJ = -project SwiftGRDBTCA.xcodeproj -skipPackagePluginValidation -skipMacroValidation -enableCodeCoverage YES
OUT = -derivedDataPath "$(PWD)/.DerivedData-iOS"
DEST = -scheme SwiftGRDBTCA -destination "platform=iOS Simulator,name=iPad (10th generation)"
QUIET = -quiet -skipMacroValidation
TEST = -testPlan SwiftGRDBTCA -only-test-configuration Sanitizing
XCCOV = xcrun xccov view --report --only-targets

default: percentage

percentage: coverage
	awk '/ SwiftGRDBTCA.app / { print $$4 }' coverage.txt > percentage.txt
	cat percentage.txt
	@if [[ -n "$$GITHUB_ENV" ]]; then \
        echo "PERCENTAGE=$$(< percentage.txt)" >> $$GITHUB_ENV; \
    fi

coverage: test
	$(XCCOV) $(PWD)/.DerivedData-iOS/Logs/Test/*.xcresult > coverage.txt
	cat coverage.txt

test: build
	xcodebuild -skipMacroValidation $(PROJ) $(OUT) test-without-building $(DEST) $(TEST)

build: clean
	xcodebuild $(QUIET) $(PROJ) $(OUT) build-for-testing $(DEST)

clean:
	xcodebuild $(QUIET) clean ${DEST}
	rm -rf "$(PWD)/.DerivedData-iOS"

.PHONY: build test coverage clean
