Pod::Spec.new do |s|
  s.name         = "GMGridView"
  s.version      = "1.1.2"
  s.summary      = "A performant Grid-View for iOS (iPhone/iPad) that allows sorting of views with gestures (the user can move the items with his finger to sort them) and pinching/rotating/panning gestures allow the user to play with the view and toggle from the cellview to a fullsize display."
  s.description  = <<-DESC
                   A longer description of GMGridView in Markdown format.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC
  s.platform     = :ios
  s.homepage     = "https://github.com/gmoledina/GMGridView"
  s.license      = "MIT"
  s.author             = { "Gulam Moledina" => "http://www.gmoledina.ca" }
  s.source       = { :git => "https://github.com/gmoledina/GMGridView.git", :tag => "1.1.2" }
  s.source_files  = "GMGridView", "GMGridView/*.{h,m}"
  s.public_header_files = "GMGridView", "GMGridView/*.h"
  s.requires_arc = true
  s.framework = 'QuartzCore'
end
