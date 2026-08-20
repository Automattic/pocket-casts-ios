# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/helpers'

# Tests the project-specific helpers used to prepare TestFlight changelogs and App Store metadata.
class FastlaneHelpersTest < Minitest::Test
  def test_ios_changelog_excludes_tvos_entries
    release_notes = <<~NOTES
      - Improve the iOS player
      - [tvOS] Add a TV player
      - Mention [tvOS] later in an iOS note
    NOTES

    expected = <<~NOTES.chomp
      - Improve the iOS player
      - Mention [tvOS] later in an iOS note
    NOTES

    assert_equal expected, ios_testflight_changelog(release_notes)
  end

  def test_ios_changelog_uses_fallback_when_only_tvos_entries_exist
    assert_equal 'Minor changes.', ios_testflight_changelog("- [tvOS] Add a TV player\n")
  end

  def test_tvos_changelog_filters_entries_and_strips_marker
    release_notes = <<~NOTES
      - Improve the iOS player
      - [tvOS] Add a TV player
      - Fix the iOS queue
      - [tvOS] Fix the TV queue
    NOTES

    expected = <<~NOTES.chomp
      - Add a TV player
      - Fix the TV queue
    NOTES

    assert_equal expected, tvos_testflight_changelog(release_notes)
  end

  def test_tvos_changelog_ignores_empty_entries
    release_notes = "- [tvOS]\n- [tvOS] \t\n- [tvOS] Keep this entry\n"

    assert_equal '- Keep this entry', tvos_testflight_changelog(release_notes)
  end

  def test_tvos_changelog_requires_exact_marker_and_uses_fallback
    release_notes = <<~NOTES
      - Mention [tvOS] later in an iOS note
      - [TVOS] Use a differently-cased marker
      - [tvOS feature] Use a longer marker
    NOTES

    assert_equal 'Minor changes.', tvos_testflight_changelog(release_notes)
  end

  def test_changelogs_accept_marker_without_separator
    release_notes = "- [tvOS]No separator\n"

    assert_equal 'Minor changes.', ios_testflight_changelog(release_notes)
    assert_equal '- No separator', tvos_testflight_changelog(release_notes)
  end

  def test_metadata_length_verdict_is_ok_up_to_the_budget
    assert_equal :ok, app_store_metadata_length_verdict('description.txt', 3399)
    assert_equal :ok, app_store_metadata_length_verdict('description.txt', 3400)
    assert_equal :ok, app_store_metadata_length_verdict('keywords.txt', 95)
  end

  def test_metadata_length_verdict_warns_between_the_budget_and_the_maximum
    assert_equal :over_budget, app_store_metadata_length_verdict('description.txt', 3401)
    assert_equal :over_budget, app_store_metadata_length_verdict('description.txt', 4000)
    assert_equal :over_budget, app_store_metadata_length_verdict('keywords.txt', 96)
    assert_equal :over_budget, app_store_metadata_length_verdict('keywords.txt', 100)
  end

  def test_metadata_length_verdict_fails_past_the_maximum
    assert_equal :over_max, app_store_metadata_length_verdict('description.txt', 4001)
    assert_equal :over_max, app_store_metadata_length_verdict('keywords.txt', 101)
    assert_equal :over_max, app_store_metadata_length_verdict('subtitle.txt', 31)
    assert_equal :over_max, app_store_metadata_length_verdict('release_notes.txt', 4001)
  end

  def test_metadata_length_verdict_never_warns_without_a_budget
    assert_equal :ok, app_store_metadata_length_verdict('subtitle.txt', 30)
    assert_equal :ok, app_store_metadata_length_verdict('release_notes.txt', 4000)
  end

  def test_metadata_length_verdict_rejects_an_unknown_file
    assert_raises(KeyError) { app_store_metadata_length_verdict('changelog.txt', 1) }
  end

  # `RUN_FASTLANE_TESTS` enables this suite for any PR touching `fastlane/*`, which includes the metadata
  # itself — so over-long copy fails on the PR that writes it, not mid-release.
  #
  # Budgets are asserted, not just maximums: a budget only warns from the release lane, and a warning
  # nobody reads is how a locale ends up shipping with no metadata at all.
  def test_shipped_metadata_fits_its_limits
    %w[metadata metadata-tvos].each do |folder|
      APP_STORE_METADATA_LIMITS.each do |file_name, limits|
        path = File.expand_path("../#{folder}/default/#{file_name}", __dir__)
        length = File.read(path, mode: 'r:UTF-8').rstrip.length
        budget = limits[:budget] ? "#{limits[:budget]}-character budget, " : ''

        assert_equal :ok, app_store_metadata_length_verdict(file_name, length),
                     "#{path} is #{length} characters, over its #{budget}#{limits.fetch(:max_size)}-character maximum"
      end
    end
  end
end
