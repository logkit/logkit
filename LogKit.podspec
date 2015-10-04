Pod::Spec.new do |s|
    s.name = 'LogKit'
    s.version = '1.1.0'
    s.authors = 'Justin Pawela', 'The LogKit Project'
    s.license = { :type => 'BSD', :file => 'LICENSE.txt' }
    s.summary = 'An efficient logging library for iOS and OS X, written in Swift.'
    s.description = 'An efficient logging library for iOS and OS X, written in Swift. Log to console, file, HTTP service, or your own endpoint. Simple to get started, but smartly customizable.'
    s.homepage = 'http://www.logkit.info/'
    s.source = { :git => 'https://github.com/logkit/logkit.git', :tag => s.version }
    s.documentation_url = 'http://www.logkit.info/docs/'

    s.ios.deployment_target = '8.0'
    s.osx.deployment_target = '10.9'

    s.requires_arc = true
    s.frameworks = 'Foundation'

    s.source_files = 'Source/LogKit.swift'
end
