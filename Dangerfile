# frozen_string_literal: true

github.dismiss_out_of_range_messages

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn('PR is classed as Work in Progress') if github.pr_title.include? '[WIP]'

swiftformat.binary_path = 'Pods/SwiftFormat/CommandLineTool/swiftformat'
# NOTE: We can only run SwiftFormat on the added or modified files
swiftformat.check_format(fail_on_error: true)

rubocop.lint inline_comment: true, fail_on_inline_comment: true
