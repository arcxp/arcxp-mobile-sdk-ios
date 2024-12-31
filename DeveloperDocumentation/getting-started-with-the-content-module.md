# Getting started with ArcXP Content iOS Module

Arc XP Content iOS module is a part of the unified mobile framework package that provides features for fetching content data of various formats that can be displayed in your iOS application.

## Prerequisites

There are three things you'll need to do before writing any code. Each of these are detailed in the following instructions.

1. Make sure you have the required data points for configuration  
2. Test your outbound feeds  
3. Set up your backend and resolver for Mobile SDK

You'll need four ArcXP Content data points to initialize the Content iOS module:

* Organization name
* Server environment
* Site
* Host domain/base URL

If you don't have these values yet, your ArcXP Contact should be able to provide them for you.

Test your outbound feeds endpoint by entering the URL below into any web browser.

Add your base URL to this endpoint:

```
{your base URL}/arc/outboundfeeds/navigation/default
```

Example:

```
https://arcsales-arcsales-sandbox.web.arc-cdn.net/arc/outboundfeeds/navigation/default
```

If this URL returns JSON, then the outbound feed is set up. If it returns an error then the outbound feed is not set up, or may be set up incorrectly, and the Content iOS module will not work.

If an error is returned, you should contact your ArcXP Contact to create an ACS ticket for further investigation.

If JSON is returned, indicating things are working as expected, continue by following both of these instructions closely:

* [Backend Setup For Mobile SDK](back-end-setup-for-mobile-sdk.md)
* [Resolver Setup For Mobile SDK](mobile-sdk-resolver-setup.md)

After everything above has been resolved, you're now ready to begin implementing the Content iOS module into your project.

## Installation steps

1. In your project, go to your project's target, and click **Package Dependencies** at the top.  
2. Click the **+** sign to add a new Swift package dependency.  
3. In the **Search or Enter Package URL** field, enter the following URL: <br /><br />`https://github.com/arc-partners/ArcXPContentSDK-iOS-SP.git`<br /><br />
4. Make and adjustments if needed for any specific versions you might want, or leave the Dependency Rule on "Up to Next Major Version".  
5. Click the **Add Package** button, and **Add Package** again on the following pop up.  
6. Navigate to any file where you'd like to use the ArcXP Content iOS module, and import it with the following line. <br /><br />`import ArcXP`

## Set Up Content Module Configuration

Use your four ArcXP Content data points to populate the parameter fields of your `ArcXPContentConfig` instance, as seen in the example below.

```
let contentConfiguration = ArcXPContentConfig(organizationName: <#org#>, serverEnvironment: <#env#>, site: <#site#>, hostDomain: <#domain#>)
```

Then call the `setUp()` method on `ArcXPContentManager`.

```
ArcXPContentManager.setUp(with: contentConfiguration)
```

Now you're ready to begin fetching content for use in your iOS application. For details on how to do so, check out our Using Content iOS module documentation.

If you get stuck on any of the steps above, reach out to your Technical Account Manager to find clarification on anything you might need.
