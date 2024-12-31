# Getting started with Arc XP Subscriptions iOS Module

**The Arc XP Subscriptions iOS module** includes identity and paywall features, to manage create and manage user accounts, and to determine which content your users should be allowed to view or not.

To use the ArcXP Subscriptions module, follow the detailed steps below.

## Prerequisites

Before you begin adding ArcXP Subscriptions iOS module to your project, there are a few things to take care of.

Get your ArcXP configuration details from your ArcXP contact. These include:

1. Back-end base URL  
2. Organization  
3. Site  
4. Environment

These details are required for configuring the Subscriptions module in your project. Without the correct configuration details, the framework will not work.

Test your base URL to make sure your backend is responding properly. This can be done in any web browser. In your web browser, enter the following URL:

```
{your base url}/identity/public/v1/config
```

Example:
```
https://arcsales-arcsales-sandbox.api.cdn.arcpublishing.com/identity/public/v1/config
```

If the URL above does not work for you, there may be a problem with how your ArcXP backend was set up, and you should reach out to your ArcXP contact create a ticket on diagnosing the issue.

After you've retrieved your configuration details and verified that the backend is working correctly, you can start setting up your project with the required dependencies.

## Dependencies

With consideration for the features you want to implement, you may omit any of these dependencies, but know that you may need to sort these dependencies out in the future if you decide to use the module features which rely on them.

First, make sure your project has been set up to work with Swift Package Manager. For more information, visit the [Swift Package Manager](https://www.swift.org/documentation/package-manager) documentation.

Include the [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) package dependency in your project. For instructions on how to add package dependencies to projects, visit [Adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

## Installation & Setup steps

Follow the installation and setup steps outlined in [Getting Started with Arc XP iOS SDK](getting-started-initialization.md) document for getting started with the Arc XP iOS SDK.

[comment]: # (Now you're ready to start implementing ArcXP Subscriptions features in your project. For more details on what you can do with ArcXP Subscriptions iOS module, check out our [documentation](getting-started-with-the-commerce-module.md)

## Additional Documentation

* [Using the Subscriptions iOS module](using-the-subscriptions-module-paywall.md)
