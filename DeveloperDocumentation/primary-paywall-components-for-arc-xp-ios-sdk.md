# Primary Paywall Components for Arc XP iOS SDK

Commerce Paywall manages content access using Rules, Entitlements, and Conditions. Learn more about these components below.

## Paywall Rule

Paywall Rules, from the backend Commerce Paywall service, govern content access with values like rule ID, campaign info, a budget limiting content access frequency, and Entitlements and Conditions specifying applicable users and content.

## User Rule

Stored locally on devices, User Rules track user interactions with Paywall Rules, including matched rule IDs, content viewed associated with the rule, and a counter with a reset date to manage content access limits for the rule.

## Entitlement

Entitlements, also referred to as SKUs, are simple strings determining a rule's relevance to a user. For example, one entitlement might be "premium". They also contain Edgescapes for geolocation-based permission management.

## Page View Data

Page View Data refers to information related to a "page view" rather than the actual page content. It consists of the page ID and corresponding Conditions. These Conditions help determine what Paywall Rules the Page View Data should be governed by.

## Conditions

Conditions exist in Page View Data and Paywall Rules, and help to determine their relevance to each other. Paywall Rule Conditions include an `isIn` value for evaluation, while Page View Data Conditions have only the string value. Client Conditions are also be considered when comparing Page View Data to a Paywall Rule.

## Additional Documentation

- [Paywall Algorithm Flowchart](PaywallAlgorithmFlowchart.pdf)
- [How to use Commerce Paywall](using-the-subscriptions-module-paywall.md)