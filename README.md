[![codecov](https://codecov.io/gh/arcxp/arcxp-mobile-sdk-iOS/graph/badge.svg)](https://codecov.io/gh/arcxp/arcxp-mobile-sdk-iOS)
# Arc XP iOS SDK
The primary Arc XP framework for Apple platforms.
Arc XP services included with this framework are Commerce, Content, and Video services.

## Internal Developer Documentation
- [Commerce Service Technical Architecture Diagram](DeveloperDocumentation/CommerceServiceTechnicalArchitectureDiagram.pdf)
- [Video Service Technical Architecture Diagram](DeveloperDocumentation/VideoServiceTechinicalArchitectureDiagram.pdf)



A collection of documentation covering the Arc XP unified mobile SDK and sample projects.

## Backend Setup

Before any of Arc XP's services can be used, a backend must be ready to connect to. See the reference below for more details. If you're only developing for iOS and Android platforms, you shouldn't need to do any backend setup, and will simply need the backend configuration details to use the SDK. 

* [Backend setup for Mobile SDK](/DeveloperDocumentation/back-end-setup-for-mobile-sdk.md)
* [Mobile SDK - Resolver setup](/DeveloperDocumentation/mobile-sdk-resolver-setup.md)

## Mobile SDK

Arc XP's mobile SDK allows access to Arc XP services and content, for Android and iOS applications. Access to the various services and media is available via a single SDK, documentation can be found around the following modules (commerce/content being optional).

* **(Subscriptions)** Identity services for user management.
* **(Content)** Fetching media to display in applications.
* **(Video)** Fetching video on demand, and connecting to livestreams.  
      

**[Mobile SDK Initialization](/DeveloperDocumentation/getting-started-initialization.md)**  

[Frequently Asked Questions](/DeveloperDocumentation/frequently-asked-questions.md)

## Security Best Practices

Follow these best practices to keep your application secure while using Arc XP mobile SDK.

[Security Best Practices](/DeveloperDocumentation/security-best-practices.md)

## Content Module

Optional Content module provides access to various types of content managed by Arc XP services, including text, photo, and video formats. 

### Using the Module

[Using the Arc XP Content iOS module](/DeveloperDocumentation/getting-started-with-the-content-module.md)

## Subscriptions Module

Optional Subscriptions module handles Identity services, such as logging in with Subscriptions and third party social network services.

### Getting started

 [Getting Started with the Arc XP Subscriptions iOS Module](/DeveloperDocumentation/getting-started-with-the-commerce-module.md)

### Using the Module

[Using the Subscriptions iOS SDK Paywall](/DeveloperDocumentation/using-the-subscriptions-module-paywall.md)

## Video Module

Video module handles delivering video content, including ads, served by Arc XP services.


### Video module documentation


[Getting Started](/DeveloperDocumentation/getting-started-with-the-video-module.md)


[Callbacks on iOS and tvOS](/DeveloperDocumentation/mobile-video-module-callbacks-on-ios-and-tvos.md)


[Configuring ads for iOS and tvOS](/DeveloperDocumentation/mobile-video-module-configuring-ads-with-the-ios-sdk.md)


[Configuring the Arc XP SDK client on iOS and tvOS](/DeveloperDocumentation/mobile-video-sdk-configuring-the-arc-sdk-client-on-ios-and-tvos.md)


[Configuring closed captioning on iOS and tvOS](/DeveloperDocumentation/mobile-video-module-configuring-closed-captioning-on-ios-and-tvos.md)


[Controlling playback on iOS and tvOS](/DeveloperDocumentation/mobile-video-sdk-controlling-video-playback-with-the-ios-sdk.md)

[Customizing the player on iOS and tvOS](/DeveloperDocumentation/mobile-video-module-customizing-the-player-on-ios.md)

## Sample Apps

Arc XP's mobile sample apps demonstrate what using Arc XP services in real world applications might look like, while also providing a starting point for updating and customizing the project into something more suited to a specific client.

When it comes to cross platform development and using our mobile SDK we have experimented with React Native and found a way to incorporate our SDK into a RN project. Please see the article here: [Using Mobile SDK with React Native](/DeveloperDocumentation/using-mobile-sdk-with-react-native.md)

### The Arc XP - News App

The Arc XP News demonstrates Arc XP services built into a mobile news app.

[The Arc XP (News App) iOS Sample Project](/DeveloperDocumentation/the-arc-xp-news-app-sample-project.md), [Widget](/DeveloperDocumentation/newsapp-widget-documentation.md)
* General: [AdMob Integration](/DeveloperDocumentation/the-arc-xp-news-app-google-admob-implementation.md)



## Client Documentation
- [Enable Picture in Picture](ClientDocumentation/EnablePictureInPicture.md)
