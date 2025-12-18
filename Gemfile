# frozen_string_literal: true

source 'https://rubygems.org'

gem 'commonmarker'
gem 'danger-dangermattic', '~> 1.0'
gem 'fastlane', '~> 2.216'
gem 'fastlane-plugin-firebase_app_distribution', '~> 0.10'
gem 'fastlane-plugin-sentry', '~> 1.14'
gem 'fastlane-plugin-wpmreleasetoolkit', '~> 13.8'
# To avoid errors like:
#
# SSL_connect returned=1 errno=0 peeraddr=3.5.132.155:443 state=error: certificate verify failed (unable to get certificate CRL)
#
# See https://github.com/ruby/openssl/issues/949
gem 'openssl', '~> 4.0'
gem 'rubocop', '~> 1.60'
gem 'watchbuild'

# At some point, the Rake gem end up at version 13.x. At the time of writing,
# the release-toolkit Fastlane pluging requires it to be `~> 12.3`. This repo
# doesn't use Rake directly, so, to ensure the dependencies can resolve, let's
# relax its constraint.
gem 'rake', '>= 12.0', '< 14.0'
