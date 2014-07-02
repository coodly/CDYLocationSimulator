Pod::Spec.new do |spec|
  spec.name         = 'CDYLocationSimulator'
  spec.version      = '0.1.0'
  spec.summary      = "Utility classes to simulate location changes on iOS platform."
  spec.homepage     = "https://github.com/coodly/CDYLocationSimulator"
  spec.author       = { "Jaanus Siim" => "jaanus@coodly.com" }
  spec.source       = { :git => "https://github.com/coodly/CDYLocationSimulator.git", :tag => "v#{spec.version}" }
  spec.license      = { :type => 'Apache 2', :file => 'LICENSE' }
  spec.requires_arc = true

  spec.subspec 'Core' do |ss|
    ss.platform = :ios, '7.0'
    ss.source_files = 'Core/*.{h,m}'
    ss.dependency 'Ono'
    ss.framework = 'CoreLocation'
  end
end
