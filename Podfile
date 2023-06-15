# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'TransTracks' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TransTracks
  
  # Crash logging
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'

  # General Firebase
  pod 'Firebase/Firestore'
  
  # Firebase Auth
  pod 'FirebaseUI'
  
  # Ads
  pod 'Google-Mobile-Ads-SDK'

  # Password Text Field
  pod 'PasswordTextField'

  # RX
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxSwiftExt'
  
  # Toast
  pod 'Toast-Swift', '~> 5.0.0'
  
  # ZIP Foundation
  pod 'ZIPFoundation'

  target 'TransTracksTests' do
    inherit! :search_paths
    
    pod 'RxBlocking'
    pod 'RxTest'
  end

  target 'TransTracksUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
               end
          end
   end
end
