# frozen_string_literal: true

github.dismiss_out_of_range_messages

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn('PR is classed as Work in Progress') if github.pr_title.include? '[WIP]'

swiftformat.binary_path = 'Pods/SwiftFormat/CommandLineTool/swiftformat'
swiftformat.exclude = %w[Pods/**]
# This line is very long. There are of course ways in Ruby to split it into
# multiple lines but there might be something even better we could do e.g.  by
# using a configuration file for SwiftFormat or making the Danger pluing accept
# an array.
#
# Before addressing that, we ought to move back to the upstream version, see
# https://github.com/shiftyjelly/pocketcasts-ios/issues/4022
#
# In the meantime, let's silence RuboCop for this line.
#
# rubocop:disable Layout/LineLength
swiftformat.additional_args = '--commas inline --stripunusedargs closure-only --elseposition next-line --trimwhitespace nonblank-lines --swiftversion 5 --exclude podcasts/Strings+Generated.swift --exclude fastlane/SnapshotHelper.swift --exclude **/**/*.pb.swift'
# rubocop:enable Layout/LineLength
swiftformat.check_format(fail_on_error: true)

rubocop.lint inline_comment: true, fail_on_inline_comment: true
