# frozen_string_literal: true

source 'https://cdn.cocoapods.org/'

use_modular_headers!

inhibit_all_warnings!

app_ios_deployment_target = Gem::Version.new('15.0')

def common_pods
  pod 'google-cast-sdk-no-bluetooth', git: 'https://github.com/shiftyjelly/google-cast.git'
  pod 'MaterialComponents/BottomSheet'
end

target 'podcasts' do
  platform :ios, app_ios_deployment_target.version
  common_pods
end

target 'PocketCastsTests' do
  platform :ios, app_ios_deployment_target.version
  common_pods
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
