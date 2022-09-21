BUNDLE=rbenv exec bundle
LANG_VAR=LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
FASTLANE=$(LANG_VAR) $(BUNDLE) exec fastlane

help: ## Show this list of commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

swift_percentage: ## Swift and Obj-C percentage on the project
	./scripts/count.rb

generate_colors: ## Generate colors and themes based on themes.csv
	ruby scripts/themes/generate_themes.rb scripts/themes/theme.csv
	swiftformat --commas inline --stripunusedargs closure-only --elseposition next-line --trimwhitespace nonblank-lines ./podcasts/ThemeColor.swift ./podcasts/ThemeStyle.swift

swiftformat: ## Run swiftformat
	./Pods/SwiftFormat/CommandLineTool/swiftformat --commas inline --stripunusedargs closure-only --elseposition next-line --trimwhitespace nonblank-lines --swiftversion 5 podcasts PodcastsIntents Modules fastlane "Pocket Casts Watch App Extension" "WidgetExtension" PocketCastsTests --exclude podcasts/Strings+Generated.swift --exclude fastlane/SnapshotHelper.swift --exclude **/Protobuffer/*.swift

upload_dsyms: ## Upload dSYMs
	./scripts/upload-symbols -gsp $(HOME)/.configure/pocketcasts-ios/secrets/GoogleService-Info.plist -p ios ./podcasts.app.dSYM.zip

install_dependencies: ## Install dependencies to run this project
	bundle install
	bundle exec pod install --repo-update

update_proto: ## Generates the protobuffer Swift files
	./scripts/update_proto.sh $(API_PATH)

external_contributor: ## Generates an empty ApiCredentials.swift so the app builds
	@cp podcasts/Credentials/ApiCredentials.tpl podcasts/Credentials/LocalApiCredentials.swift
	@sed -i '' 's/%{.*}//' "podcasts/Credentials/LocalApiCredentials.swift"
	$(info You're ready to build the app, go ahead! 🎙)
