platform :ios, '8.0'
swift_version = '2.3'
use_frameworks!
target 'TimerQuiz' do
  pod 'RealmSwift'
  pod 'Charts', '2.3.0'
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '2.3'
      end
    end
  end
end
