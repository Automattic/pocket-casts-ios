# frozen_string_literal: true

TVOS_NOTE_PREFIX = '- [tvOS]'

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

# The phased-release announcement, keeping the wording the release scenario posted by hand.
#
# `RELEASE_VERSION` and `MILESTONE` are passed by the Releases V2 Buildkite action. `MILESTONE` is
# only sent once the Releases V2 side stops posting this message by hand, so the milestone-less
# wording is what ships until then.
#
# @param fallback_version [String] Version to announce when `RELEASE_VERSION` is not set, as on a manual run.
# @return [String] The slack message body to use, typically in a call to the `slack()` fastlane action
#
def phased_release_slack_message(fallback_version:)
  version = ENV.fetch('RELEASE_VERSION', nil).to_s.strip
  version = fallback_version if version.empty?

  milestone = ENV.fetch('MILESTONE', nil).to_s.strip
  subject = ["`#{version}`", milestone].reject(&:empty?).join(' ')

  ":announcement: #{subject} has started phased release."
end
