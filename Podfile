# Apple TV workspace

target 'dreamhouse' do

project 'dreamhousetv.xcodeproj'

source 'https://github.com/douglowder/SalesforceMobileSDK-iOS-Specs.git' # need to be first
source 'https://github.com/CocoaPods/Specs.git'

pod 'ReactTV', :path => './node_modules/react-native', :subspecs => [
  'Core',
  'CSSLayout',
  'RCTImage',
  'RCTNetwork',
  'RCTText',
  'RCTWebSocket',
  'RCTLinkingIOS'
]

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'c++14'
    end
  end
end

pod 'SalesforceSDKCoreTV'
pod 'SalesforceNetworkTV'
pod 'SalesforceRestAPITV'
pod 'SmartStoreTV'
pod 'SmartSyncTV'
pod 'SalesforceReactTV'

end

