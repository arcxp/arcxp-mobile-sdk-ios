# Using the Subscriptions iOS Module - Paywall

The Subscriptions iOS module contains Paywall features that determine whether users should be allowed to view content by considering a set of data, including **Rules**, **Entitlements**, and **Conditions**. **Paywall Rules** and **Entitlements** are automatically fetched from the backend, and compared against **Page View Data** and **Conditions** provided by the module user.

To view **Paywall Rules** and **Entitlements** provided by the back end, see the following references. Note that you normally won't need to fetch and retrieve these yourself, but it may be valuable to view them separately for development and debugging reasons.

## Active Paywall Rules

```swift
let paywallRules = PaywallManager.activePaywallRules
print(paywallRules)
```

### Entitlements

```swift
let entitlements = PaywallManager.entitlementResponse
print(entitlements)
```

## Page View Data and Conditions

**Page View Data** and **Conditions** are values that are initialized by the module user. To see how each are initialized and provided to the `PaywallManager`, take a look at `PaywallStatusViewController` in the Example project.

## Page View Data

`PageViewData` describes content that the user may view, as well as page specific conditions. That data includes a page ID and conditions that describe a specific page/content.

```swift
let pageViewData = PageViewData(pageId: "007", conditions: ["contentType": "article"])
```

## Conditions

Conditions are values that describe either content or client details (client refers to the application or platform using the Subscriptions iOS module). Conditions describing content information live within `PageViewData`, and might describe something like a `contentType` being an `article`. Conditions describing client information are wrapped by a type called `ClientCondition` and might describe something like `clientType` being `mobile`. Both are provided to the `PaywallManager`, where they are used to consider whether a user can view specific content or not.

Conditions used for `PageViewData` are initialized as a simple dictionary value. See the example above to see exactly how that can be done.

Client Conditions are handled by a specific type, and can be prepared as seen below. Given that client conditions describe the application/platform, these values can be defined early in the lifetime of the application, and simply passed in whenever an evaluation happens. For testing, we allow the creation of Client Conditions in `ClientConditionsViewController`.

```swift
let clientConditions = ClientCondition.deviceClass(value: "mobile")
```

## Paywall Evaluation

After initializing `PageViewData` and `ClientConditions`, the `PaywallManager` can take those data points into consideration when determining whether a user should view content or not.

## Count Page View

Note the parameter below for `countPageView`. This determines whether or not the user's budget for viewing content should be updated with this evaluation. If `false` is provided, then the evaluation result returns normally, without affecting the user's budget. But if, for example, you're evaluating the user's ability to view an article on the article page, and want to count the view against the user's budget, setting `countPageView` to `true` also updates the user's budget.

```swift
let evaluationResult = PaywallManager.evaluate(pageViewData: pageViewData, clientConditions: clientConditions, countPageView: true)
        
switch evaluationResult {
case .success(let rules):
    print("Successfully evaluated all rules.")
    
case .failure(let error):
    print("There was an error while evaluating paywall rules.")
            
    switch error {
    case .rulesTripped(let rules):
        print("One or more rules have tripped. Tripped rules: \(rules)")
    case .noActivePaywallRules:
        print("No active paywall rules were available to evaluate against.")
    }
}
```

## Example result

```
(lldb) po evaluationResult
▿ Result<UserRules, PaywallManagerError>
  ▿ success : UserRules
    ▿ rules : 3 elements
      ▿ 0 : 2 elements
        - key : 962
        ▿ value : <UserRule: 0x600001e104b0>
      ▿ 1 : 2 elements
        - key : 963
        ▿ value : <UserRule: 0x600001e10930>
      ▿ 2 : 2 elements
        - key : 987
        ▿ value : <UserRule: 0x600001e11a40>
```

Based on this result, you can see all rules have passed due to the `success` print out, meaning the user can be shown the content. Otherwise, `failure` is returned, and the user should not be shown that content. 

## Conclusion

After initializing the required `PageViewData` and any relevant `ClientCondition` values, you primarily use `evaluate(pageViewData:clientConditions:countPageView:)` to assess whether a user should be shown content or not. That method takes all the required data points into consideration, including automatically pulled Paywall Rules and Entitlements, and returns a result indicating whether content should be shown or not.

## Additional Documentation
- [Paywall Algorithm Flowchart](PaywallAlgorithmFlowchart.pdf)
