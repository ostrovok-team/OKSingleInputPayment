Pod::Spec.new do |s|
  s.name         = "OKSingleInputPayment"
  s.version      = "0.4.8"
  s.summary      = "A customizable implementation of Square's single input payment for iOS."
  s.homepage     = "http://ostrovok.ru"
  s.license      = 'MIT'
  
  s.author       = { "Ryan Romanchuk" => "rromanchuk@gmail.com" }
  s.source       = { :git => "https://github.com/ostrovok-team/OKSingleInputPayment.git", :tag => "0.4.8" }
  s.platform     = :ios, '5.0'
  s.source_files = 'src/*.{h,m}'
  s.resource     =  'src/OKSingleInputPayment.bundle'
  s.requires_arc = true
end
