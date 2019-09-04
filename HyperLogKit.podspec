Pod::Spec.new do |s|
    s.name = 'HyperLogKit'
    s.version = '3.0.14'
    s.authors = 'SolusGuard HyperLogKit'
    s.license = { :type => 'BSD', :file => 'LICENSE.txt' }
    s.summary = 'An efficient logging library for iOS – written in Swift.'
    s.description = 'An efficient logging library for iOS – written in Swift. Log to console, file, HTTP service, Core Data or your own endpoint. Simple to get started, but smartly customizable.'
    s.homepage = 'https://github.com/solusguard/HyperLogKit/'
    s.source = { :git => 'https://github.com/solusguard/HyperLogKit.git', :tag => s.version }
    s.documentation_url = 'https://github.com/solusguard/HyperLogKit/'

    s.swift_version = '5.0'
    s.ios.deployment_target = '11.0'

    s.requires_arc = true
    s.frameworks = 'Foundation'
    s.frameworks = 'CoreData'
    s.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-DLogKitAdvertisingIDDisabled' }

    s.source_files = 'Sources/*.swift'
    s.resource_bundles = {'HyperLogKit' => ['Sources/*.xcdatamodeld']}
end
