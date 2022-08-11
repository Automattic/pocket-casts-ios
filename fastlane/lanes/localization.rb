# frozen_string_literal: true

# The folder where all the `.lproj` folders are located
LPROJ_ROOT_FOLDER = File.join(PROJECT_ROOT_FOLDER, 'podcasts')

EN_LPROJ_FOLDER = File.join(LPROJ_ROOT_FOLDER, 'en.lproj')

# List of `.strings` files manually maintained by developers (as opposed to
# being automatically extracted from code and generated) which we will merge
# into the main `Localizable.strings` file imported by GlotPress, then extract
# back once we download the translations.
#
# Each `.strings` file to be merged/extracted is associated with a prefix to
# add to the keys, used to avoid conflicts and differentiate the source of the
# copies.
#
# See calls to `ios_merge_strings_files` and
# `ios_extract_keys_from_strings_files` for usage.
MANUALLY_MAINTAINED_STRINGS_FILES = {
  File.join(EN_LPROJ_FOLDER, 'InfoPlist.strings') => 'infoplist',
  File.join(EN_LPROJ_FOLDER, 'Intents.strings') => 'siri_intent_definition_key'
}.freeze

# URL of the GlotPress project containing the strings used in the app
GLOTPRESS_APP_STRINGS_PROJECT_URL = 'https://translate.wordpress.com/projects/pocket-casts/ios/'
# URL of the GlotPress project containing App Store Connect metadata
GLOTPRESS_APP_STORE_METADATA_PROJECT_URL = 'https://translate.wordpress.com/projects/pocket-casts/ios/release-notes/'

# List of locales used for the app strings (GlotPress code => `*.lproj` folder name`).
# Sorted like Xcode sorts them in the File Inspector for easier comparison.
#
# TODO: Replace with `LocaleHelper` once provided by release toolkit (https://github.com/wordpress-mobile/release-toolkit/pull/296)
GLOTPRESS_TO_LPROJ_APP_LOCALE_CODES = {
  'zh-cn' => 'zh-Hans', # Chinese (China, Simplified)
  'zh-tw' => 'zh-Hant', # Chinese (Taiwan, Traditional)
  'nl' => 'nl',         # Dutch
  'fr' => 'fr',         # French
  'fr-ca' => 'fr-CA',   # French (Canadian)
  'de' => 'de',         # German
  'it' => 'it',         # Italian
  'ja' => 'ja',         # Japanese
  'pt-br' => 'pt-BR',   # Portuguese (Brazil)
  'ru' => 'ru',         # Russian
  'es' => 'es',         # Spanish
  'es-mx' => 'es-MX',   # Spanish (Mexico)
  'sv' => 'sv'          # Swedish
}.freeze

# Mapping of all locales which can be used for AppStore metadata
# (GlotPress code => AppStore Connect code)
#
# TODO: Replace with `LocaleHelper` once provided by release toolkit
# (https://github.com/wordpress-mobile/release-toolkit/pull/296)
GLOTPRESS_TO_ASC_METADATA_LOCALE_CODES = {
  'de' => 'de-DE',
  'es' => 'es-ES',
  'fr' => 'fr-FR',
  'it' => 'it',
  'ja' => 'ja',
  'nl' => 'nl-NL',
  'pt-br' => 'pt-BR',
  'ru' => 'ru',
  'sv' => 'sv',
  'zh-cn' => 'zh-Hans',
  'zh-tw' => 'zh-Hant'
}.freeze

# Generates the `.strings` file to be imported by GlotPress, by parsing source
# code.
#
# @note Uses `genstrings` under the hood.
# @called_by `complete_code_freeze`.
#
lane :generate_strings_file_for_glotpress do
  # For reference: Other apps run `cocoapods` here (equivalent to `bundle
  # exec pod install`) because they have internal libraries that bring in
  # their own strings. Pocket Casts does not have dependencies with strings
  # fetched via CocoaPods, so we don't need to waste time on that.

  # Other apps call `ios_generate_strings_file_from_code` as the first step
  # of this process, but Pocket Casts iOS uses the convention of defining all
  # localized strings in the `en.lproj/Localizable.strings` file and then use
  # SwiftyGen to generate reference to them for the code. With this approach,
  # there are no `NSLocalizedStrings` in the codebase and that action would
  # be useless.

  # Merge various manually-maintained `.strings` files into the previously
  # generated `Localizable.strings` so their extra keys are also imported in
  # GlotPress.
  #
  # Note: We will re-extract the translations back during
  # `download_localized_strings_from_glotpress` (via a call to
  # `ios_extract_keys_from_strings_files`)
  ios_merge_strings_files(
    paths_to_merge: MANUALLY_MAINTAINED_STRINGS_FILES,
    destination: File.join(EN_LPROJ_FOLDER, 'Localizable.strings')
  )

  git_commit(
    path: [EN_LPROJ_FOLDER],
    message: 'Update strings for localization',
    allow_nothing_to_commit: true
  )
end

desc 'Downloads localized strings and App Store Connect metadata from GlotPress'
lane :download_localized_strings_and_metadata_from_glotpress do
  download_localized_strings_from_glotpress
  download_localized_app_store_metadata_from_glotpress
end

desc 'Downloads localized `.strings` from GlotPress'
lane :download_localized_strings_from_glotpress do
  ios_download_strings_files_from_glotpress(
    project_url: GLOTPRESS_APP_STRINGS_PROJECT_URL,
    locales: GLOTPRESS_TO_LPROJ_APP_LOCALE_CODES,
    download_dir: LPROJ_ROOT_FOLDER
  )
  git_commit(
    path: File.join(LPROJ_ROOT_FOLDER, '*.lproj', 'Localizable.strings'),
    message: 'Update app translations – `Localizable.strings`',
    allow_nothing_to_commit: true
  )

  # Redispatch the appropriate subset of translations back to the
  # manually-maintained `.strings` files that we merged at the
  # `complete_code_freeze` time via `ios_merge_strings_files`.
  modified_files = ios_extract_keys_from_strings_files(
    source_parent_dir: LPROJ_ROOT_FOLDER,
    target_original_files: MANUALLY_MAINTAINED_STRINGS_FILES
  )
  git_commit(
    path: modified_files,
    message: 'Update app translations – Other `.strings`',
    allow_nothing_to_commit: true
  )
end

desc 'Downloads localized metadata for App Store Connect from GlotPress'
lane :download_localized_app_store_metadata_from_glotpress do
  # FIXME: Replace this with a call to the future replacement of
  # `gp_downloadmetadata` once it's implemented in the release-toolkit (see
  # paaHJt-31O-p2).
  target_files = {
    "v#{ios_get_app_version}-whats-new": {
      desc: 'release_notes.txt',
      max_size: 4000
    },
    app_store_subtitle: { desc: 'subtitle.txt', max_size: 30 },
    app_store_desc: { desc: 'description.txt', max_size: 4000 },
    app_store_keywords: { desc: 'keywords.txt', max_size: 100 }
  }

  gp_downloadmetadata(
    project_url: GLOTPRESS_APP_STORE_METADATA_PROJECT_URL,
    target_files: target_files,
    locales: GLOTPRESS_TO_ASC_METADATA_LOCALE_CODES,
    download_path: APP_STORE_METADATA_FOLDER
  )
  files_to_commit = [File.join(APP_STORE_METADATA_FOLDER, '**', '*.txt')]

  # Ensure that none of the `.txt` files in `en-US` would accidentally
  # override our originals in `default`
  target_files.values.map { |h| h[:desc] }.each do |file|
    en_file_path = File.join(APP_STORE_METADATA_FOLDER, 'en-US', file)
    next unless File.exist?(en_file_path)

    UI.user_error!("File `#{en_file_path}` would override the same one in `#{APP_STORE_METADATA_FOLDER}/default
`, but `default/` is the source of truth. " \
+ "Delete the `#{en_file_path}` file, ensure the `default/` one has the expected orig
inal copy, and try again.")
  end

  # Ensure even empty locale folders have an empty `.gitkeep` file (in case
  # we don't have any translation at all ready for some locales)
  GLOTPRESS_TO_ASC_METADATA_LOCALE_CODES.each_value do |locale|
    gitkeep = File.join(APP_STORE_METADATA_FOLDER, locale, '.gitkeep')
    next if File.exist?(gitkeep)

    FileUtils.mkdir_p(File.dirname(gitkeep))
    FileUtils.touch(gitkeep)
    files_to_commit.append(gitkeep)
  end

  # Commit
  git_add(path: files_to_commit, shell_escape: false)
  git_commit(
    path: files_to_commit,
    message: 'Update App Store metadata translations',
    allow_nothing_to_commit: true
  )
end

desc 'Lint the `.strings` files'
lane :lint_localizations do
  ios_lint_localizations(input_dir: File.join(PROJECT_ROOT_FOLDER, 'podcasts'), allow_retry: true)
end

# This lane updates the `AppStoreStrings.po` file for the Pocket Casts app
# with the latest content from the `release_notes.txt` file and the other
# text sources
#
desc 'Updates the `AppStoreStrings.po` file for the Pocket Casts app with the latest data'
lane :update_app_store_strings do
  source_metadata_folder = File.join(APP_STORE_METADATA_FOLDER, 'default')
  version = get_version_number(xcodeproj: 'podcasts.xcodeproj', target: 'podcasts')

  files = {
    whats_new: File.join(source_metadata_folder, 'release_notes.txt'),
    app_store_subtitle: File.join(source_metadata_folder, 'subtitle.txt'),
    app_store_desc: File.join(source_metadata_folder, 'description.txt'),
    app_store_keywords: File.join(source_metadata_folder, 'keywords.txt')
  }

  ios_update_metadata_source(
    po_file_path: File.join(PROJECT_ROOT_FOLDER, 'fastlane', 'AppStoreStrings.po'),
    source_files: files,
    release_version: version
  )
end

# Checks the translation progress (%) of all Mag16 for all the projects (app
# strings and metadata) in GlotPress.
#
# @option [Boolean] interactive (default: false) If true, will pause and ask
# confirmation to continue if it found any locale translated below the
# threshold
#
desc 'Check translation progress for all GlotPress projects'
lane :check_all_translations_progress do |options|
  abort_on_violations = false
  skip_confirm = options.fetch(:interactive, false) == false

  UI.message('Checking app strings translation status...')
  check_translation_progress(
    glotpress_url: GLOTPRESS_APP_STRINGS_PROJECT_URL,
    abort_on_violations: abort_on_violations,
    skip_confirm: skip_confirm
  )

  UI.message('Checking release notes strings translation status...')
  check_translation_progress(
    glotpress_url: GLOTPRESS_APP_STORE_METADATA_PROJECT_URL,
    abort_on_violations: abort_on_violations,
    skip_confirm: skip_confirm
  )
end
