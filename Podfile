# frozen_string_literal: true

source 'https://cdn.cocoapods.org/'

use_modular_headers!

inhibit_all_warnings!

app_ios_deployment_target = Gem::Version.new('15.0')

def kingfisher
  # Any version compatible with 7.6, starting from 7.6.2 to ensure
  # compatibility with Xcode 14.3.
  #
  # Notice that 7.6.2 is not necessarily the first version compatible with
  # Xcode 14.3 but it was the latest version at the time we checked and so
  # we are using it as the baseline.
  pod 'Kingfisher', '~> 7.6', '>= 7.6.2'
end

def common_pods
  pod 'JLRoutes'
  pod 'google-cast-sdk-no-bluetooth', git: 'https://github.com/shiftyjelly/google-cast.git'
  kingfisher
end

target 'podcasts' do
  platform :ios, app_ios_deployment_target.version
  common_pods
end

target 'PocketCastsTests' do
  platform :ios, app_ios_deployment_target.version
  common_pods
end

target 'Pocket Casts Watch App Extension' do
  platform :watchos, '6.0'
  kingfisher
end

abstract_target 'CI' do
  platform :ios, app_ios_deployment_target.version

  pod 'SwiftGen', '~> 6.0'
  pod 'SwiftLint', '~> 0.49'
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      if t.name != 'Pocket Casts Watch App Extension'
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] =
          app_ios_deployment_target.version
      end
    end
  end
end
