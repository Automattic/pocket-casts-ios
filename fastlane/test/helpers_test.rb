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

  def test_description_length_verdict_is_ok_up_to_the_budget
    assert_equal :ok, app_store_description_length_verdict(3399, max_size: 4000, budget: 3400)
    assert_equal :ok, app_store_description_length_verdict(3400, max_size: 4000, budget: 3400)
  end

  def test_description_length_verdict_warns_between_the_budget_and_the_maximum
    assert_equal :over_budget, app_store_description_length_verdict(3401, max_size: 4000, budget: 3400)
    assert_equal :over_budget, app_store_description_length_verdict(4000, max_size: 4000, budget: 3400)
  end

  def test_description_length_verdict_fails_past_the_maximum
    assert_equal :over_max, app_store_description_length_verdict(4001, max_size: 4000, budget: 3400)
  end

  def test_description_length_verdict_defaults_to_the_app_store_sizes
    assert_equal :ok, app_store_description_length_verdict(APP_STORE_DESCRIPTION_SOURCE_MAX_SIZE)
    assert_equal :over_budget, app_store_description_length_verdict(APP_STORE_DESCRIPTION_SOURCE_MAX_SIZE + 1)
    assert_equal :over_max, app_store_description_length_verdict(APP_STORE_DESCRIPTION_MAX_SIZE + 1)
  end

  # `RUN_FASTLANE_TESTS` enables this suite for any PR touching `fastlane/*`, which includes the metadata
  # itself — so an over-long description fails on the PR that writes the copy, not mid-release.
  def test_shipped_descriptions_fit_the_app_store_connect_maximum
    %w[metadata metadata-tvos].each do |folder|
      path = File.expand_path("../#{folder}/default/description.txt", __dir__)
      length = File.read(path, mode: 'r:UTF-8').length

      assert_operator length, :<=, APP_STORE_DESCRIPTION_MAX_SIZE, "#{path} is #{length} characters"
    end
  end
end
