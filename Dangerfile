# frozen_string_literal: true

github.dismiss_out_of_range_messages

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn('PR is classed as Work in Progress') if github.pr_title.include? '[WIP]'

rubocop.lint inline_comment: true, fail_on_inline_comment: true

swiftlint.binary_path = './Pods/SwiftLint/swiftlint'
# Lint all files to ensure maximum coverage.
swiftlint.lint_all_files = true
swiftlint.lint_files
