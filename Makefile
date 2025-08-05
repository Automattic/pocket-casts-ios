BUNDLE=rbenv exec bundle
LANG_VAR=LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
FASTLANE=$(LANG_VAR) $(BUNDLE) exec fastlane
SWIFTLINT_FROM_BUILDTOOLS=swiftlint lint --working-directory .. --quiet

define run_in_buildtools
	@pushd BuildTools && \
	export SDKROOT=$$(xcrun --sdk macosx --show-sdk-path) && \
	swift package plugin \
		--allow-writing-to-directory .. \
		--allow-writing-to-package-directory \
		$(1) && \
	popd
endef

help: ## Show this list of commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

swift_percentage: ## Swift and Obj-C percentage on the project
	./scripts/count.rb

generate_colors: ## Generate colors and themes based on themes.csv
	ruby scripts/themes/generate_themes.rb scripts/themes/theme.csv

generate_code:
	$(call run_in_buildtools,generate-code-for-resources --config ../swiftgen.yml)

lint:
	$(call run_in_buildtools,$(SWIFTLINT_FROM_BUILDTOOLS))

lint_lenient:
	$(call run_in_buildtools,$(SWIFTLINT_FROM_BUILDTOOLS) --lenient)

format:
	$(call run_in_buildtools,$(SWIFTLINT_FROM_BUILDTOOLS) --autocorrect)

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
