# frozen_string_literal: true

source 'https://cdn.cocoapods.org/'

use_modular_headers!

inhibit_all_warnings!

app_ios_deployment_target = Gem::Version.new('15.0')

def common_pods
  pod 'google-cast-sdk-no-bluetooth', git: 'https://github.com/shiftyjelly/google-cast.git'
end

def swiftlint_version
  require 'yaml'

  YAML.load_file('.swiftlint.yml')['swiftlint_version']
end

target 'podcasts' do
  platform :ios, app_ios_deployment_target.version
  common_pods
  pod 'PulseCore', :git => 'https://github.com/kean/Pulse.git', :tag => '4.2.4', :configurations => ['Debug', 'Staging', 'Prototype']
  pod 'PulseUI', :git => 'https://github.com/kean/Pulse.git', :tag => '4.2.4', :configurations => ['Debug', 'Staging', 'Prototype']
end

target 'PocketCastsTests' do
  platform :ios, app_ios_deployment_target.version
  common_pods
end

abstract_target 'CI' do
  platform :ios, app_ios_deployment_target.version

  pod 'SwiftGen', '~> 6.0'
  pod 'SwiftLint', swiftlint_version
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
