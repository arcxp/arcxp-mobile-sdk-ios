# ArcXP
#
# Verifying:
# pod spec lint ArcXP.podspec --private --allow-warnings --sources=arc-partners,trunk --verbose
#
# Releasing:
# pod repo push arc-mobile-podspecs ArcXP.podspec --private --allow-warnings --skip-import-validation --sources=arc-partners,trunk --verbose

Pod::Spec.new do |spec|
  # Meta
  spec.name         = 'ArcXP'
  spec.version      = '1.3.1'
  spec.summary      = 'ArcXP SDK that includes Commerce, Content, and Video services'
  spec.author       = 'Arc XP, The Washington Post'
  spec.homepage     = 'https://arcxp.com/'
  spec.license      = {
    :type => 'Commercial',
    :text => <<-LICENSE
    © The Washington Post. All rights reserved.
    LICENSE
  }

  # Settings
  spec.static_framework    = true
  spec.swift_version       = '5.0'
  spec.cocoapods_version   = '>= 1.7.0'

  # Deployment Targets
  spec.platforms = { :ios => "15.0", :tvos => "15.0"}
  spec.ios.deployment_target = 15.0
  spec.tvos.deployment_target = 15.0

  # The DESTINATION for the pod (or, in this case, the zipped files). Publishing the pod
  # does NOT zip the frameworks up and upload them to this location--you have to do that
  # manually.
  spec.source = { :http => 'https://github.com/arcxp/arcxpSDK-iOS-package/raw/refs/heads/main/Frameworks.zip' }

  # The path the frameworks in the SOURCE .ZIP that are going into the pod.
  # The path the frameworks IN THE SOURCE .ZIP that are going into the pod. You have to
  # zip these up into a file called deploy.zip and upload it
  # to the location specified in spec.source, above.
  spec.ios.vendored_frameworks = ['ArcXP.xcframework', 'GoogleInteractiveMediaAds.xcframework', 'OMSDK_Washpost.xcframework', 'ProgrammaticAccessLibrary.xcframework']
  spec.tvos.vendored_frameworks = ['ArcXP.xcframework', 'GoogleInteractiveMediaAds.xcframework', 'ProgrammaticAccessLibrary.xcframework']
  
end

