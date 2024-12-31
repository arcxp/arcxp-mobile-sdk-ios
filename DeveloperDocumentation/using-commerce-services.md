# Using Commerce Services with Arc XP iOS SDK

This document provides an overview of how to leverage the Commerce service provided by Arc XP iOS SDK. The Commerce service consists of two sets of features, including Identity and Paywall, with an upcoming expansion to include Subscriptions.

Keep in mind that this document serves as a brief introduction, containing simple descriptions of the API provided by Arc XP iOS SDK. Comprehensive documentation, including web API endpoints and potential error responses from the backend, can be found in the Swagger documentation.

If you haven't already downloaded and installed the Arc XP iOS SDK, please refer to our "Getting Started with Arc XP iOS SDK" guide, which includes step-by-step instructions for downloading, installing, and configuring the framework.

## Identity

The Identity features provided by the Arc XP iOS SDK include ways to create and manage user accounts. Some of these features include starting an account with Arc XP Commerce or from a third party social media account, and updating the user profile for existing accounts.

### Identity Struct

Identity is a Struct that is part of the Commerce class. Its functions are static and correspond with the endpoints in the Identity web API. These include signing up, logging in, updating user account data, and other related tasks.

### Account Management

#### Current User Details

After signing in or log in, a user profile object will be provided in the completion block, and will also live statically in Commerce.

Note that this will return cached user data, and may not always represent the most up-to-date data for the user. To get the latest user data, see the \`fetchUserProfile(completion:)\` method below.

#### UserProfile

UserProfile contains all the data belonging to a user, intended to be used for the current user.

#### Sign Up

Register a new user with their profile info, remembering their session if desired, and using reCaptcha for added security.

```swift
static func signUp(  
    user: UserProfile,   
    rememberMe: Bool = false,   
    reCaptchaToken: String? = nil,   
    completion: @escaping UserCompletion)
```

#### Log In

Log a user in with their username and password, optionally remembering their session, and using reCaptcha for security.

```swift
static func logIn(  
    username: String,  
    password: String,  
    rememberMe: Bool = false,  
    reCaptchaToken: String? = nil,  
    completion: @escaping UserCompletion)  
 ``` 

#### Extend user session

Prolong a user's session.

```swift
static func extendUserSession(  
    completion: @escaping ServiceCompletion)
```

#### Get access token

Retrieve an access token for a user's session.

```swift
static func getAccessToken(  
    completion: @escaping (Result<JWT, Error>) -> Void)  
```  

### Profile Management

#### Fetch the users profile

Obtain a user's profile information and process it if needed.

```swift
static func fetchUserProfile(  
    completion: UserCompletion?)
```

#### Commit user profile updates

Save any changes made to a user's profile.

```swift
static func commitUserProfileUpdates(  
    completion: @escaping UserCompletion)  
```

### Password Management

#### Request a password reset

Help a user who forgot their password by sending a reset link to their email.

```swift
static func requestResetPassword(  
    username: String,   
    completion: @escaping ServiceCompletion)  
```

#### Reset password

Update the user's password using a provided nonce and new password.

```swift
static func resetPassword(  
    nonce: String,   
    newPassword: String,   
    completion: @escaping ServiceCompletion)  
```

#### Update password

Change a user's password by providing the old and new passwords.

```swift
static func updatePassword(  
    oldPassword: String,   
    newPassword: String,   
    completion: @escaping ServiceCompletion)  
``` 

### One-Time Access Links

#### Request one time access link

Send a one-time access link to a user's email, with optional reCaptcha.

```swift
static func requestOneTimeAccessLink(  
    email: String,   
    reCaptchaToken: String? = nil,   
    completion: @escaping ServiceCompletion)  
```  

#### Redeem one time access link

Use a one-time access link to grant temporary access and confirm the action.

```swift
static func redeemOneTimeAccessLink(  
    nonce: String,   
    completion: @escaping ServiceCompletion)  
```  

### Account Deletion

#### Request account deletion

Initiate the process of deleting a user's account.

```swift
static func requestDeleteAccount(  
    completion: @escaping ServiceCompletion)  
```  

#### Approve account deletion

Confirm the deletion of a user's account using a provided nonce.

```swift
static func approveDeleteAccount(  
    _ nonce: String,   
    completion: @escaping ServiceCompletion)  
```  

#### Decline account deletion

Cancel the deletion of a user's account, providing a reason for the decision.

```swift
static func declineDeleteAccount(  
    _ nonce: String,   
    _ reason: DeletionDeclineReason,   
    completion: @escaping ServiceCompletion)  
```  

### Backend Configuration

#### Get config

Fetch Commerce configuration details.

```swift
static func getConfig(  
    completion: @escaping (Result<ConfigOptions, Error>) -> Void)
```