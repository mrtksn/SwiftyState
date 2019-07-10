#
# Be sure to run `pod lib lint SwiftyState.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftyState'
  s.version          = '1.0'
  s.summary          = 'A State Engine with a debug UI on iOS and iPadOS'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  With SwiftyState you create a single struct to keep all your data in, then you create actions to change that data. That struct is a central source of truth and you can subscribe to receive changes without worry about the rest of the application. You also get a GUI where you can see the state and even revert and replay the changes.
                       DESC

  s.homepage         = 'https://github.com/mrtksn/SwiftyState'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mrtksn' => 'mrtksn@gmail.com' }
  s.source           = { :git => 'https://github.com/mrtksn/SwiftyState.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  s.source_files = 'SwiftyState/Classes/**/*'
  s.resources = ['SwiftyState/Classes/*.xib']
 

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
