Pod::Spec.new do |s|
s.name             = 'FNDebugManagerPod'
s.version          = '0.1.0'
s.summary          = 'A short description of FNDebugManagerPod.'

s.description      = <<-DESC
TODO: Add long description of the pod here.
DESC

s.homepage         = 'www.feiniu.com'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'JR' => 'jiaruijj@163.com' }
s.source           = { :svn => "http://svnserver01.fn.com/ios/fn-ios/FNComponents/FNDebugManager/trunk" }

s.ios.deployment_target = '7.0'
s.source_files = 'FNDebugManagerPod/Classes/**/*.{h,m}'
s.resource_bundles = {
    'FNDebugManagerPod' => ['FNDebugManagerPod/**/*.{cer,xib}']
}

#s.subspec 'FNVoiceManager' do |ss|
#ss.source_files = 'FNDebugManagerPod/Classes/**/*.{h,m,mm}'
#ss.public_header_files = 'FNDebugManagerPod/Classes/**/*.h'
#ss.vendored_libraries = 'FNDebugManagerPod/Classes/**/*.a'
#ss.dependency  'FMDB'
#end

# s.public_header_files = 'Pod/Classes/**/*.h'
# s.frameworks = 'UIKit', 'MapKit'
# s.dependency 'AFNetworking', '~> 2.3'
end
