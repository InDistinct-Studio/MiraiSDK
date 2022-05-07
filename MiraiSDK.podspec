#
# Be sure to run `pod lib lint MiraiSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MiraiSDK'
  s.version          = '1.0.2'
  s.summary          = 'MiraiSDK detect and verify Thai national ID cards.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  MiraiSDK automatically captures high-quality document image with AI for no Copy of
  Thai ID Card. There are a bit laser or light reflect on image and return id number data.
                       DESC

  s.homepage         = 'https://github.com/northanapon/MiraiSDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'northanapon' => 'nor.thanapon@gmail.com' }
  s.source           = { :http => 'https://github.com/InDistinct-Studio/MiraiSDK/releases/download/1.0.2/MiraiSDK-v1.0.2.zip' }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'
  s.swift_versions = '5.0'
  s.static_framework = true
  s.ios.vendored_frameworks = 'MiraiSDK.xcframework'
  s.resources = 'MiraiSDK.bundle'
  
  s.dependency 'GoogleMLKit/TextRecognition', '>=2.3'
  s.dependency 'GoogleMLKit/ObjectDetectionCustom', '>=2.3'
  s.dependency 'GoogleMLKit/ImageLabelingCustom', '>=2.3'
  # s.resource_bundles = {
  #   'MiraiSDK' => ['MiraiSDK/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

