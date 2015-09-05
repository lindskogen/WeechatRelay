#
#  Be sure to run `pod spec lint weechat-relay.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "weechat-relay"
  s.version      = "0.0.1"
  s.summary      = "Swift library to communicate with weechat clients"
  s.homepage     = "https://github.com/lindskogen/WeechatRelay"
  s.license      = "MIT"
  s.author       = { "Johan Lindskogen" => "johan.lindskogen@gmail.com" }
  s.source       = { :git => "https://github.com/lindskogen/WeechatRelay.git", :tag => "0.0.1" }
  s.source_files  = "WeechatRelay"
  s.exclude_files = "WeechatRelay/main.swift"

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.requires_arc = true
  s.dependency "CocoaAsyncSocket", "~> 7.4.2"
end
