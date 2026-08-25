PLATFORM_IOS = iOS Simulator,name=iPad mini (A17 Pro)
PLATFORM_MACOS = macOS
SCHEME = SwiftGRDBTCA
WORKSPACE = $(PWD)/.workspace
BUILD_FLAGS = -skipPackagePluginValidation \
			  -skipMacroValidation \
			  -enableCodeCoverage YES \
			  -project SwiftGRDBTCA.xcodeproj \
			  -scheme $(SCHEME) \
			  -clonedSourcePackagesDirPath "$(WORKSPACE)"
XCB = | xcbeautify --renderer github-actions

OUT = -derivedDataPath "$(PWD)/.DerivedData-iOS"
DEST = -destination platform="$(PLATFORM_IOS)"
TEST = -testPlan SwiftGRDBTCA -only-test-configuration Sanitizing
XCCOV = xcrun xccov view --report --only-targets

default: report

report: coverage
	awk '/ SwiftGRDBTCA.app / { print $$4 }' coverage.txt > percentage.txt
	cat percentage.txt
	@if [[ -n "$$GITHUB_ENV" ]]; then \
        echo "PERCENTAGE=$$(< percentage.txt)" >> $$GITHUB_ENV; \
    fi

coverage: test
	$(XCCOV) $(PWD)/.DerivedData-iOS/Logs/Test/*.xcresult > coverage.txt
	cat coverage.txt

test: clean
	xcodebuild test $(BUILD_FLAGS) $(OUT) $(DEST) $(XCB)

clean:
	rm -rf "$(PWD)/.DerivedData-iOS" "$(WORKSPACE)" coverage.txt percentage.txt

.PHONY: report coverage test clean
