//
//  PaywallManager.swift
//  AppAuth
//
//  Created by David Seitz Jr on 7/21/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

/// Manages Paywall responsibilities.
public class PaywallManager {

    /// Describes errors that may occur while working with Paywall.
    public enum PaywallManagerError: LocalizedError {
        case noActivePaywallRules
        case rulesTripped(rule: TrippedRule?)

        public var errorDescription: String? {
            switch self {
            case .noActivePaywallRules:
                return NSLocalizedString("Found no active Paywall rules to evaluate against.", comment: "No active paywall rules found.")
            case .rulesTripped(_):
                return NSLocalizedString("Rule is tripped.", comment: "Rule tripped.")
            }
        }
    }

    /// Rules provided by the Paywall backend, to be evaluated with page view data, and client conditions.
    public static var activePaywallRules: [PaywallRule]?

    /// Entitlements that have been pulled down for the current user.
    public static var entitlementResponse: EntitlementsResponse?

    /// Setup the PaywallManager with the user's entitlements and active Paywall rules.
    static func setup() {
        loadEntitlements()
        loadPaywallRulesWithUserRules()
    }

    /// Fetch the user's entitlements.
    /// - parameter completion: The completion handler to call after the user's entitlements have been fetched, providing an error if one occurs.
    static func loadEntitlements(completion: ((Result<Void, Error>) -> Void)? = nil) {
        Subscriptions.Sales.fetchEntitlements { entitlementsResult in
            switch entitlementsResult {
            case .success(let entitlementsResponse):
                entitlementResponse = entitlementsResponse
                completion?(.success)
            case .failure(let error):
                print("Commerce: PaywallManager - An error occured while loading paywall entitlements. Error: \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
    }

    /// Fetch active Paywall rules.
    /// - parameter completion: The completion handler to call after active Paywall rules have been fetched, providing an error if one occurs.
    static func loadPaywallRulesWithUserRules(completion: ((Result<Void, Error>) -> Void)? = nil) {
        Subscriptions.Retail.getPaywallRules { result in
            switch result {
            case .success(let paywallRules):
                activePaywallRules = paywallRules
                completion?(.success)
            case .failure(let error):
                print("Commerce: PaywallManager - An error occured while loading paywall active rules. Error: \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
    }

    /// Evaluate whether a user can view content, with consideration for provided page view data and client conditions.
    /// - parameter pageViewData: The page view data to be evalauted with Paywall rules, and the user's cached data.
    /// - parameter clientConditions: Conditions describing client/platform specific values.
    /// - parameter countTowardsBudget: If true, counts a view towards the budget of any matching Paywall rules.
    /// - parameter readDate: Primarily used for testing,  allows you to review the result that would occur on any given date. Note, this will affect the cache if `countTowardsBudget` is set to true.
    ///  - returns: Cached user rules, including cached page views, or an error if one occured.
    public static func evaluate(contentID: String,
                                conditions: [String: String]? = nil,
                                countTowardsBudget: Bool,
                                readDate: Date = Date()) -> Result<Void, PaywallManagerError> {

        guard let paywallRules = activePaywallRules else {
            return .failure(PaywallManagerError.noActivePaywallRules)
        }

        var trippedRule: TrippedRule?
        var ruleTripped = false
        for paywallRule in paywallRules {
            let evaluationResult = PaywallEvaluator.evaluate(userEntitlements: entitlementResponse,
                                                             paywallRule: paywallRule,
                                                             contentID: contentID,
                                                             conditions: conditions,
                                                             countTowardsBudget: countTowardsBudget,
                                                             readDate: readDate)
            switch evaluationResult {
            case .budgetExceeded(let rule):
                // Saving the first rule that trips so we can return it in the error.
                if ruleTripped == false {
                    ruleTripped = true
                    trippedRule = TrippedRule(ruleId: paywallRule.id, rule: rule, campaignLink: paywallRule.campaignLink ?? "")
                }
            default:
                break
            }
        }
        return ruleTripped ? .failure(.rulesTripped(rule: trippedRule)) : .success(())
    }
}

/// A rule that has been tripped.
public struct TrippedRule {
    public let ruleId: Int
    public let rule: UserRules.UserRule
    public let campaignLink: String
}
