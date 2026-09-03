# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/helpers'

# Tests the project-specific helpers used to prepare TestFlight changelogs.
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

  def test_phased_release_message_omits_the_milestone_when_it_is_not_set
    assert_equal ':announcement: `7.94` has started phased release.',
                 phased_release_slack_message(version: '7.94')
  end

  def test_phased_release_message_includes_the_milestone_when_it_is_set
    assert_equal ':announcement: `7.94` (Milestone 7.94) has started phased release.',
                 phased_release_slack_message(version: '7.94', milestone: '(Milestone 7.94)')
  end

  def test_phased_release_message_trims_surrounding_whitespace
    assert_equal ':announcement: `7.94` (Milestone 7.94) has started phased release.',
                 phased_release_slack_message(version: "\t7.94\n", milestone: ' (Milestone 7.94) ')
  end

  def test_phased_release_message_drops_a_blank_milestone_rather_than_padding_the_subject
    ['', "  \n", nil].each do |milestone|
      assert_equal ':announcement: `7.94` has started phased release.',
                   phased_release_slack_message(version: '7.94', milestone: milestone)
    end
  end
end
