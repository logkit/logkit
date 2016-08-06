Pod::Spec.new do |s|
    s.name = 'LogKit'
    s.version = '2.3.2'
    s.authors = 'Justin Pawela', 'The LogKit Project'
    s.license = { :type => 'BSD', :file => 'LICENSE.txt' }
    s.summary = 'An efficient logging library for OS X, iOS, tvOS, and watchOS – written in Swift.'
    s.description = 'An efficient logging library for OS X, iOS, tvOS, and watchOS – written in Swift. Log to console, file, HTTP service, or your own endpoint. Simple to get started, but smartly customizable.'
    s.homepage = 'http://www.logkit.info/'
    s.source = { :git => 'https://github.com/logkit/logkit.git', :tag => s.version }
    s.documentation_url = 'http://www.logkit.info/docs/2.3/'

    s.osx.deployment_target = '10.9'
    s.ios.deployment_target = '8.0'
    s.watchos.deployment_target = '2.0'
    s.tvos.deployment_target = '9.0'

    s.requires_arc = true
    s.frameworks = 'Foundation'
    s.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-DLogKitAdvertisingIDDisabled' }

    s.source_files = 'Sources/*.swift'
end
