BUNDLE=rbenv exec bundle
LANG_VAR=LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
FASTLANE=$(LANG_VAR) $(BUNDLE) exec fastlane
# SwiftLint is pinned by BuildTools/Package.resolved, which takes its version
# from `swiftlint_version` in .swiftlint.yml. Run the resolved binary directly:
# `swift package plugin` adds ~0.4s of startup to every invocation.
SWIFTLINT_BIN=BuildTools/.build/artifacts/swiftlintplugins/SwiftLintBinary/SwiftLintBinary.artifactbundle/macos/swiftlint
# Explicit --config prevents SwiftLint from picking up nested configs in
# BuildTools/.build/checkouts/.
SWIFTLINT=$(SWIFTLINT_BIN) lint --config .swiftlint.yml --quiet
# Each checkout gets its own simulator so that parallel test runs from
# different worktrees don't share the test database
SIMULATOR_ID ?= $(shell scripts/test_simulator.sh)
TEST_RESULTS ?= build/TestResults.xcresult
XCBEAUTIFY := $(shell command -v xcbeautify)

# Runs the tests in scheme $(1), beautifying the output when xcbeautify is
# installed (otherwise printing only warnings and errors), then prints a summary
define run_tests
	@rm -rf "$(TEST_RESULTS)"
	@set -o pipefail; \
	xcodebuild test -project podcasts.xcodeproj \
		-scheme "$(1)" \
		-only-testing:$(ONLY_TESTING) \
		-destination 'platform=iOS Simulator,id=$(SIMULATOR_ID)' \
		-resultBundlePath "$(TEST_RESULTS)" \
		-collect-test-diagnostics never \
		$(if $(XCBEAUTIFY),2>&1 | $(XCBEAUTIFY) --quiet,-quiet); \
	status=$$?; \
	scripts/test_summary.sh "$(TEST_RESULTS)"; \
	exit $$status
endef

.PHONY: help build clean test lint lint_changed lint_lenient format install_dependencies

help: ## Show this list of commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

swift_percentage: ## Swift and Obj-C percentage on the project
	./scripts/count.rb

generate_colors: ## Generate colors and themes based on themes.csv
	ruby scripts/themes/generate_themes.rb scripts/themes/theme.csv

# Downloads the pinned SwiftLint artifact bundle on a fresh checkout, and
# re-resolves when the pin changes so a version bump takes effect.
$(SWIFTLINT_BIN): BuildTools/Package.resolved .swiftlint.yml
	@cd BuildTools && SDKROOT=$$(xcrun --sdk macosx --show-sdk-path) swift package --manifest-cache none resolve
	@test -x $@ || { echo "error: swiftlint not found at $@ after resolving BuildTools" >&2; exit 1; }
	@touch $@

lint: $(SWIFTLINT_BIN) ## Lint the codebase
	@$(SWIFTLINT)

lint_changed: $(SWIFTLINT_BIN) ## Lint Swift files changed since the branch forked from trunk
	@{ git diff --name-only -z --diff-filter=d $$(git merge-base HEAD origin/trunk 2>/dev/null || echo HEAD) -- '*.swift'; \
		git ls-files -z --others --exclude-standard -- '*.swift'; } \
		| xargs -0 $(SWIFTLINT) --force-exclude

lint_lenient: $(SWIFTLINT_BIN)
	@$(SWIFTLINT) --lenient

build: ## Builds the Debug configuration using Xcode
	xcodebuild -project podcasts.xcodeproj \
       -scheme pocketcasts \
       -configuration Debug \
       -destination 'generic/platform=iOS Simulator' \
       build

clean: ## Cleans the build artifacts
	xcodebuild -project podcasts.xcodeproj \
       -scheme pocketcasts \
       -configuration Debug \
       clean

ONLY_TESTING ?= PocketCastsTests

test: ## Build and run the PocketCastsTests target with Unit Tests using Xcode
	$(call run_tests,pocketcasts)

build_staging: ## Builds using the StagingDebug configuration
	xcodebuild -project podcasts.xcodeproj \
       -scheme "Pocket Casts Staging" \
       -configuration StagingDebug \
       -destination 'generic/platform=iOS Simulator' \
       ARCHS=arm64 \
       build

test_staging: ## Build and run Unit Tests using the StagingDebug configuration
	$(call run_tests,Pocket Casts Staging)

format: $(SWIFTLINT_BIN) ## Lint and autocorrect linter errors
	@$(SWIFTLINT) --autocorrect

upload_dsyms: ## Upload dSYMs
	./scripts/upload-symbols -gsp $(HOME)/.configure/pocketcasts-ios/secrets/GoogleService-Info.plist -p ios ./podcasts.app.dSYM.zip

install_dependencies: ## Install dependencies to run this project
	bundle install

update_proto: ## Generates the protobuffer Swift files
	./scripts/update_proto.sh $(API_PATH)

external_contributor: ## Generates an empty ApiCredentials.swift so the app builds
	@cp podcasts/Credentials/ApiCredentials.tpl podcasts/Credentials/LocalApiCredentials.swift
	@sed -i '' 's/%{.*}//' "podcasts/Credentials/LocalApiCredentials.swift"
	$(info You're ready to build the app, go ahead! 🎙)
