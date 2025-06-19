#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_redirectly.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_redirectly'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter plugin for Redirectly dynamic links - similar to Firebase Dynamic Links but using your own backend.'
  s.description      = <<-DESC
A Flutter plugin that provides Firebase Dynamic Links-like functionality using your own Redirectly backend. 
This plugin allows you to create, manage, and handle dynamic links in your Flutter app.
                       DESC
  s.homepage         = 'https://redirectly.app'
  s.license          = { :file => '../../LICENSE' }
  s.author           = { 'Flutter Redirectly' => 'contact@redirectly.app' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end 