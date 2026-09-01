require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-abcd-rewardz"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["repository"]["url"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => package["repository"]["url"], :tag => "v#{s.version}" }

  # All iOS bridge files live under ios/
  s.source_files = "ios/**/*.{h,m,mm,swift}"

  # React Native core dependency
  s.dependency "React-Core"

  # -----------------------------------------------------------------------
  # Loylty Rewardz ABCD iOS SDK
  # The spec repo must be added ONCE in the host app's Podfile:
  #
  #   source 'https://github.com/elitesdk/LR_IOS_SPECS.git'
  #   source 'https://cdn.cocoapods.org/'
  #
  # -----------------------------------------------------------------------
  s.dependency "LRABCSDK", "1.3.0-u"

  # The module contains Swift so we need a bridging header and the Swift
  # standard libraries linked into the host app.
  s.pod_target_xcconfig = {
    "SWIFT_VERSION"                          => "5.0",
    "DEFINES_MODULE"                         => "YES",
    "EXCLUDED_ARCHS[sdk=iphonesimulator*]"   => "i386"
  }
end
