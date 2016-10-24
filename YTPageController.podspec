Pod::Spec.new do |s|
  s.name             = 'YTPageController'
  s.version          = '0.5.0'
  s.summary          = 'Yet another drop-in replacement for UIPageViewController.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  YTPageController introduces a general solution to archieve a smooth transitoin when user scrolls between view controllers, just as what Apple did in their Music App. With the help of YTPageController, you can implement the effect in a few lines.
                       DESC

  s.homepage         = 'https://github.com/yeatse/YTPageController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Yeatse CC' => 'iyeatse@gmail.com' }
  s.source           = { :git => 'https://github.com/yeatse/YTPageController.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/yeatse'

  s.ios.deployment_target = '8.0'

  s.source_files = 'YTPageController/Classes/**/*'
  s.frameworks = 'UIKit'
end
