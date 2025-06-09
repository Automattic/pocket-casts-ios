# frozen_string_literal: true

source 'https://cdn.cocoapods.org/'

use_modular_headers!

inhibit_all_warnings!

app_ios_deployment_target = Gem::Version.new('16.0')

target 'podcasts' do
  platform :ios, app_ios_deployment_target.version
end

target 'PocketCastsTests' do
  platform :ios, app_ios_deployment_target.version
end

abstract_target 'CI' do
  platform :ios, app_ios_deployment_target.version

  pod 'SwiftGen', '~> 6.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if target.name != 'Pocket Casts Watch App'
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] =
          app_ios_deployment_target.version
      end
    end
  end
end
