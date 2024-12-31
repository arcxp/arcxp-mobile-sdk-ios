# Getting started with Arc XP Commerce iOS Module

**The Arc XP Commerce iOS module** includes identity and paywall features, to manage create and manage user accounts, and to determine which content your users should be allowed to view or not.

To use the ArcXP Commerce module, follow the detailed steps below.

## Prerequisites

Before you begin adding ArcXP Commerce iOS module to your project, there are a few things to take care of.

Get your ArcXP configuration details from your ArcXP contact. These include:

- Back-end base URL  
- Organization  
- Site  
- Environment

These details are required for configuring the Commerce SDK module in your project. Without the correct configuration details, the framework will not work.

Test your base URL to make sure your backend is responding properly. This can be done in any web browser. In your web browser, enter the following URL:

```
{your base url}/identity/public/v1/config

// Example
https://arcsales-arcsales-sandbox.api.cdn.arcpublishing.com/identity/public/v1/config
```

If the URL above does not work for you, there may be a problem with how your ArcXP backend was set up, and you should reach out to your ArcXP contact create a ticket on diagnosing the issue.

After you've retrieved your configuration details and verified that the backend is working correctly, you can start setting up your project with the required dependencies.

## Dependencies

With consideration for the features you want to implement, you may omit any of these dependencies, but know that you may need to sort these dependencies out in the future if you decide to use the module features which rely on them.

First, make sure your project has been set up with CocoaPods. For more information about Cocoapods, visit [CocoaPods.org]([https://cocoapods.org](https://cocoapods.org)).

After your project has been set up with CocoaPods, make sure to include these pods in your Podfile.

```
pod 'ReCaptcha'
pod 'GoogleSignIn', "~> 5.0.2"
pod 'FBSDKLoginKit', "~> 7.1.1"
```

## Installation & Setup steps

Please follow the installation and setup steps outlined in [Getting Started with Arc XP iOS SDK](getting-started-initialization.md).

Now you're ready to start implementing ArcXP Commerce features in your project. For more details on what you can do with ArcXP Commerce iOS module, check out our [ documentation](using-commerce-services.md).

## Additional Documentation

- [Using the Commerce iOS module](using-commerce-services.md)
- [Paywall Documentation](primary-paywall-components-for-arc-xp-ios-sdk.md)
- [How to use Commerce Paywall](using-the-subscriptions-module-paywall.md)
- [Paywall Algorithm Flowchart](PaywallAlgorithmFlowchart.pdf)
