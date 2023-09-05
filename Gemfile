# frozen_string_literal: true

source 'https://rubygems.org'

gem 'cocoapods', '~> 1.12', '>= 1.12.1'
gem 'cocoapods-check', '~> 1.1'
gem 'commonmarker'
gem 'danger'
gem 'danger-rubocop', '~> 0.10'
gem 'danger-swiftlint'
gem 'fastlane', '~> 2.210.0'
gem 'fastlane-plugin-sentry', '~> 1.14'
gem 'fastlane-plugin-wpmreleasetoolkit', '~> 5.4'
gem 'rubocop', '~> 1.30'
gem 'watchbuild'

# At some point, the Rake gem end up at version 13.x. At the time of writing,
# the release-toolkit Fastlane pluging requires it to be `~> 12.3`. This repo
# doesn't use Rake directly, so, to ensure the dependencies can resolve, let's
# relax its constraint.
gem 'rake', '>= 12.0', '< 14.0'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
