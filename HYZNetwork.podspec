#
# Be sure to run `pod lib lint HYZNetwork.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HYZNetwork'
  s.version          = '1.0.1'
  s.summary          = 'HYZNetwork是基于AFNetworking3.2.1封装的iOS端简易网络库，通过创建请求对象的方式处理网络接口'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
HYZNetwork是基于AFNetworking3.2.1封装的iOS端简易网络库，通过创建请求对象的方式处理网络接口
                       DESC

  s.homepage         = 'https://github.com/zone1026/HYZNetwork'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zone1026' => '1024105345@qq.com' }
  s.source           = { :git => 'https://github.com/zone1026/HYZNetwork.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'HYZNetwork/Classes/**/*'
  
  # s.resource_bundles = {
  #   'HYZNetwork' => ['HYZNetwork/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'AFNetworking', '3.2.1'
end
