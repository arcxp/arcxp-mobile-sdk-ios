[![codecov](https://codecov.io/gh/arcxp/arcxp-mobile-sdk-iOS/graph/badge.svg)](https://codecov.io/gh/arcxp/arcxp-mobile-sdk-iOS)
# Arc XP iOS SDK
The primary Arc XP framework for Apple platforms.
Arc XP services included with this framework are Commerce, Content, and Video services.


A collection of documentation covering the Arc XP unified mobile SDK and sample projects.

## Backend Setup

Before any of Arc XP's services can be used, a backend must be ready to connect to. See the reference below for more details. If you're only developing for iOS and Android platforms, you shouldn't need to do any backend setup, and will simply need the backend configuration details to use the SDK. 

* [Backend setup for Mobile SDK](https://dev.arcxp.com/mobile/content/back-end-setup-for-mobile-sdk/)
* [Mobile SDK - Resolver setup](https://dev.arcxp.com/mobile/content/mobile-sdk-resolver-setup/)

## Mobile SDK

Arc XP's mobile SDK allows access to Arc XP services and content, for Android and iOS applications. Access to the various services and media is available via a single SDK, documentation can be found around the following modules (commerce/content being optional).

* **(Subscriptions)** Identity services for user management.
* **(Content)** Fetching media to display in applications.
* **(Video)** Fetching video on demand, and connecting to livestreams.  
      

**[Mobile SDK Initialization](https://dev.arcxp.com/mobile/getting-started/getting-started-with-arc-xp-ios-sdk/)**  

[Frequently Asked Questions](https://dev.arcxp.com/mobile/additional-resources/arc-xp-mobile-sdk-faq/)

## Security Best Practices

Follow these best practices to keep your application secure while using Arc XP mobile SDK.

[Security Best Practices](https://dev.arcxp.com/mobile/additional-resources/arc-xp-mobile-sdk-security-best-practices/)

## Content Module

Optional Content module provides access to various types of content managed by Arc XP services, including text, photo, and video formats. 

### Using the Module

[Using the Arc XP Content iOS module](https://dev.arcxp.com/content/developer-docs/using-the-arc-xp-content-ios-module/)

## Subscriptions Module

Optional Subscriptions module handles Identity services, such as logging in with Subscriptions and third party social network services.

### Getting started

 [Getting Started with the Arc XP Subscriptions iOS Module](https://dev.arcxp.com/mobile/subscriptions/getting-started-with-arc-xp-commerce-ios-module/)

### Using the Module

[Using the Subscriptions iOS SDK Paywall](https://dev.arcxp.com/mobile/subscriptions/using-the-commerce-ios-module-paywall/)

## Video Module

Video module handles delivering video content, including ads, served by Arc XP services.


### Video module documentation


[Getting Started](https://dev.arcxp.com/video-center/developer-docs/mobile-video-module-getting-started-with-the-ios-sdk/)


[Callbacks on iOS and tvOS](https://dev.arcxp.com/video-center/developer-docs/mobile-video-module-callbacks-on-ios-and-tvos/)


[Configuring ads for iOS and tvOS](https://dev.arcxp.com/video-center/developer-docs/mobile-video-module-configuring-ads-with-the-ios-sdk/)


[Configuring the Arc XP SDK client on iOS and tvOS](https://dev.arcxp.com/video-center/developer-docs/mobile-video-sdk-configuring-the-arc-sdk-client-on-ios-and-tvos/)


[Configuring closed captioning on iOS and tvOS](https://dev.arcxp.com/video-center/developer-docs/mobile-video-module-configuring-closed-captioning-on-ios-and-tvos/)


[Controlling playback on iOS and tvOS](https://dev.arcxp.com/video-center/developer-docs/mobile-video-sdk-controlling-video-playback-with-the-ios-sdk/)

[Customizing the player on iOS and tvOS](https://dev.arcxp.com/video-center/developer-docs/mobile-video-module-customizing-the-player-on-ios/)

## Sample Apps

Arc XP's mobile sample apps demonstrate what using Arc XP services in real world applications might look like, while also providing a starting point for updating and customizing the project into something more suited to a specific client.

When it comes to cross platform development and using our mobile SDK we have experimented with React Native and found a way to incorporate our SDK into a RN project. Please see the article here: [Using Mobile SDK with React Native](https://dev.arcxp.com/mobile/additional-resources/using-mobile-sdk-with-react-native/)

### The Arc XP - News App

The Arc XP News demonstrates Arc XP services built into a mobile news app.

[The Arc XP (News App) iOS Sample Project](https://dev.arcxp.com/mobile/sample-apps/the-arc-xp-news-app-ios-sample-project/), [Widget](https://dev.arcxp.com/mobile/sample-apps/ios-newsapp-widget-documentation/)
* General: [AdMob Integration](https://dev.arcxp.com/mobile/sample-apps/the-arc-xp-news-app-google-admob-implementation/)
