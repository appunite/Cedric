Pod::Spec.new do |s|

  s.name         = "Cedric"
  s.version      = "0.2.0"
  s.summary      = "Cedric - Single / multiple files downloader written in pure Swift"

  s.homepage     = "https://github.com/appunite/Cedric"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }

  s.author             = { "Szymon Mrozek" => "szymon.mrozek.sm@gmail.com" }

  s.swift_version = "4.1"
  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.11"
  s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/appunite/Cedric.git", :tag => "#{s.version}" }
  s.source_files  = "Cedric"

end