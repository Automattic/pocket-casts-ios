# frozen_string_literal: true

TVOS_NOTE_PREFIX = '- [tvOS]'

# https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/
APP_STORE_DESCRIPTION_MAX_SIZE = 4000
# Budget for the English source. Translations run longer than English, and `gp_downloadmetadata` writes
# nothing for a locale whose translation is over the maximum — leaving it with no description at all.
APP_STORE_DESCRIPTION_SOURCE_MAX_SIZE = 3400

# Use this to ensure all env vars a lane requires are set.
#
# The best place to call this is at the start of a lane, to fail early.
def require_env_vars!(*keys)
  keys.each { |key| get_required_env!(key) }
end

# Use this instead of getting values from `ENV` directly. It will throw an error if the requested value is missing.
def get_required_env!(key, env_file_path: USER_ENV_FILE_PATH)
  return ENV.fetch(key) if ENV.key?(key)

  message = "Environment variable '#{key}' is not set."

  if is_ci
    UI.user_error!(message)
  elsif File.exist?(env_file_path)
    UI.user_error!("#{message} Consider adding it to #{env_file_path}.")
  else
    env_file_example_path = 'fastlane/example.env'
    env_file_dir = File.dirname(env_file_path)
    env_file_name = File.basename(env_file_path)

    UI.user_error! <<~MSG
      #{env_file_name} not found in #{env_file_dir}!

      Please copy #{env_file_example_path} to #{env_file_path} and fill in the values for the automation you require.

      mkdir -p #{env_file_dir} && cp #{env_file_example_path} #{env_file_path}
    MSG
  end
end

# Classifies an App Store description length as `:over_max`, `:over_budget` or `:ok`.
#
# Stays free of `UI` so `fastlane/test/helpers_test.rb` can exercise it under bare Ruby, without fastlane loaded.
def app_store_description_length_verdict(length, max_size: APP_STORE_DESCRIPTION_MAX_SIZE, budget: APP_STORE_DESCRIPTION_SOURCE_MAX_SIZE)
  return :over_max if length > max_size
  return :over_budget if length > budget

  :ok
end

# Builds the iOS TestFlight changelog without tvOS-only release notes.
def ios_testflight_changelog(release_notes)
  filtered_notes = release_notes.each_line.reject { |line| line.start_with?(TVOS_NOTE_PREFIX) }.join.chomp

  filtered_notes.empty? ? +'Minor changes.' : filtered_notes
end

# Builds the tvOS TestFlight changelog from Markdown list entries marked with `[tvOS]`.
# The marker is stripped because it is selection metadata and should not be shown to testers.
def tvos_testflight_changelog(release_notes)
  filtered_notes = release_notes.each_line.filter_map do |line|
    next unless line.start_with?(TVOS_NOTE_PREFIX)

    note = line.delete_prefix(TVOS_NOTE_PREFIX).strip
    next if note.empty?

    "- #{note}"
  end.join("\n")

  filtered_notes.empty? ? +'Minor changes.' : filtered_notes
end
