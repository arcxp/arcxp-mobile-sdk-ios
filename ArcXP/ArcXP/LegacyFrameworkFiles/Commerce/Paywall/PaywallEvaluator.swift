//
//  PaywallEvaluator.swift
//  ArcXPCommerce
//
//  Created by David Seitz Jr on 3/15/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation

/// Manages the evaluation of a paywall rule to determine if a user can view content.
struct PaywallEvaluator {

    /// Reports the result after evaluating a rule for entitlements, conditions, and budgeting.
    enum EvaluationResult: Equatable {

        static func == (lhs: PaywallEvaluator.EvaluationResult, rhs: PaywallEvaluator.EvaluationResult) -> Bool {
            switch (lhs, rhs) {
            case (.entitlementsMatch, .entitlementsMatch),
                (.conditionsDontMatch, .conditionsDontMatch):
                return true

            case (.budgetNotExceeded(let lhsRule), .budgetNotExceeded(let rhsRule)),
                (.budgetExceeded(let lhsRule), .budgetExceeded(let rhsRule)):
                return lhsRule == rhsRule

            default:
                return false
            }
        }

        /// The user's entitlements allow them to view this content without consideration for a budget.
        case entitlementsMatch

        /// The user's conditions don't require budgeting for this rule.
        case conditionsDontMatch

        /// The user's conditions require budgeting for this rule, but the budget has not been exceeded.
        case budgetNotExceeded(rule: UserRules.UserRule)

        /// The user's conditions require budgeting for this rule, and the budget has been exceeded.
        case budgetExceeded(rule: UserRules.UserRule)
    }

    /// Evaluate all of the data related to determining whether a user can view content or not.
    /// - parameter contentID: The unique identifier for the content being evaluated.
    /// - parameter paywallRule: The Paywall rule governing whether the user should be budgeted or prevented from viewing content.
    /// - parameter userEntitlements: Entitlements which may allow the user to view content without being budgeted.
    /// - parameter conditions: Any application client side conditions that should be considered with the Paywall rule. Example: mobile, tablet, iOS, android, etc.
    /// - parameter readDate: The date that this evaluation is supposed to happen (mostly used for testing).
    /// - parameter countTowardsBudget: Increments the cached budget if true. Otherwise, treat this as an evaluation without incrementing the cached budget.
    /// - returns: The result of the evaluation, with true allowing the user to view content, or false indicating that the provided Paywall rule has been tripped.
    static func evaluate(userEntitlements: EntitlementsResponse?,
                         paywallRule: PaywallRule,
                         contentID: String,
                         conditions: [String: String]?,
                         countTowardsBudget: Bool,
                         readDate date: Date = Date()) -> EvaluationResult {

        // False means the rule is skipped and the user is allowed to view the content.
        // If it's true, the rule is not skipped and the user must meet the rule's conditions.
        guard evaluateEntitlements(userEntitlements: userEntitlements, paywallRules: [paywallRule]),
              evaluateGeoLocations(ruleConditions: paywallRule.conditions, geoConditions: userEntitlements?.edgescape),
              evaluatePageConditions(ruleConditions: paywallRule.conditions, pageConditions: conditions)
        else {
            return .conditionsDontMatch
        }

        // Content must be metered. Add to or update cache with page and budget data.
        let result = evaluateBudget(for: paywallRule,
                                    contentID: contentID,
                                    countTowardsBudget: countTowardsBudget,
                                    readDate: date)

        return result.viewingContentAllowed ? .budgetNotExceeded(rule: result.userRule) : .budgetExceeded(rule: result.userRule)
    }

    // MARK: - Private TypeAliases

    // Private typealiases for better readability and understanding.
    private typealias PageViewConditions = [String: String]

    // MARK: - Private Functions

    /// Evaluates the given entitlements against a set of paywall rules to determine if all conditions match.
    /// - Parameters:
    ///  - userEntitlements: The user's entitlements to be evaluated against the paywall rules.
    ///  - paywallRules: The paywall rules to be evaluated against the user's entitlements.
    static func evaluateEntitlements(userEntitlements: EntitlementsResponse?, paywallRules: [PaywallRule]) -> Bool {
        guard let userEntitlements = userEntitlements else { return true }

        return paywallRules.contains { paywallRule in // Returns false if criteria not met
            // e: [true] ent: [false] means the rule will be bypassed by a registered user
            // Check for v1 SKU-based entitlements match
            if let ruleSKUs = paywallRule.entitlementsSKUs, ruleSKUs.contains(.bool(true)) {
                // Handle cases were only a `true` SKU is provided, and registered users bypass the rule
                if ruleSKUs.count == 1 { return Subscriptions.Identity.accessToken == nil }
                // Handle SKU string matching
                let userSKUs = (userEntitlements.skus?.map { $0.sku }) ?? [String]()
                for ruleSKU in ruleSKUs {
                    if case .string(let ruleSkuString) = ruleSKU,
                       userSKUs.contains(ruleSkuString) {
                        // e: [true, 'SKU1'] ent: [false] means the rule will be bypassed by a user with “SKU1”
                        return false
                    }
                }
            }

            // Check for v2 zone-based entitlements match
            if let ruleEntitlementsZones = paywallRule.entitlementsZones,
               let userZones = userEntitlements.zones {
                for ruleZone in ruleEntitlementsZones {
                    if case .int(let ruleZoneInt) = ruleZone,
                       userZones.contains(ruleZoneInt),
                       ruleEntitlementsZones.contains(.bool(true)) {
                        // e: [false] ent: [true, 123] means the rule will be bypassed by a user with the entitlement 123
                        return false
                    }
                }
            }
            return true // No match for this rule
        }
    }

    /// Evaluates the given page conditions against a set of rule conditions to determine if all conditions match.
    ///
    /// Evaluate whether conditions exist between `ruleConditions` and `pageConditions`, with
    /// consideration for "in" and "out" sections.
    /// Conditions will be considered a match if:
    /// - For "in" conditions (`isIn` is true), the page condition's value is within the specified values of the rule.
    /// - For "out" conditions (`isIn` is false), the page condition's value is not within the specified values of the rule.
    ///
    /// The function returns true if the rule conditions match the page conditions, in terms of value and count.
    /// If no rule conditions are met,  it returns false, indicating no matches.
    ///
    /// - Parameters:
    ///   - ruleConditions: A list of conditions, which may be "in" or "out".
    ///   - pageConditions: A list of conditions to be matched against rule conditions.
    /// - Returns: A Boolean value indicating whether rule condition and page conditions match. Returns `true` if a match is found, otherwise returns `false`.
    static func evaluatePageConditions(ruleConditions: [String: RuleCondition],
                                       pageConditions: [String: String]?) -> Bool {
        guard let pageConditions = pageConditions else { return true }
        var result = true
        for (key, rule) in ruleConditions {
            if let value = pageConditions[key] {
                let conditionMet = rule.isMet(by: value)
                result = result && conditionMet
            }
        }
        return result
    }

    /// Evaluates the given geo conditions against a set of rule conditions to determine if all conditions match.
    /// - Parameters:
    ///  - ruleConditions: A list of conditions, which may be "in" or "out".
    ///  - geoConditions: The geo conditions to be matched against rule conditions.
    static func evaluateGeoLocations(ruleConditions: [String: RuleCondition],
                                     geoConditions: Edgescape?) -> Bool {
        var result = true
        for (key, rule) in ruleConditions {
            if let value = geoConditions?.geoElements?[key] {
                let conditionMet = rule.isMet(by: value)
                result = result && conditionMet
            }
        }
        return result
    }

    // swiftlint: disable cyclomatic_complexity
    private static func dateExceeded(paywallRule: PaywallRule, userRule: UserRules.UserRule, dateRead: Date) -> Bool {
        let currentDate = dateRead.startOfDay
        switch paywallRule.budget.budgetType {
        case .calendar:
            switch paywallRule.budget.calendarType {

            case .weekly:
                guard let budgetResetDate = RuleBudget.WeekdayType.date(for: paywallRule.budget.calendarWeekday, immediatelyFollowing: userRule.lastResetDate) else {
                    devPrint("PaywallManager could not find rolling reset date while evaluating budget.")
                    return false
                }

                return currentDate >= budgetResetDate

            case .monthly:
                let currentYear = Calendar(identifier: .iso8601).component(.year, from: currentDate)
                let resetYear = Calendar(identifier: .iso8601).component(.year, from: userRule.lastResetDate)
                let currentMonth = Calendar(identifier: .iso8601).component(.month, from: currentDate)
                let resetMonth = Calendar(identifier: .iso8601).component(.month, from: userRule.lastResetDate)

                if currentYear < resetYear {
                    return false
                } else if currentYear > resetYear {
                    return true
                } else if currentYear == resetYear && currentMonth <= resetMonth {
                    return false
                } else if currentYear == resetYear && currentMonth > resetMonth {
                    return true
                }

            case .none:
                return false
            }

        case .rolling:
            let resetDate = userRule.lastResetDate
            switch paywallRule.budget.rollingType {
            case .days:
                guard let rollingDays = paywallRule.budget.rollingDays else { return false }
                let expirationDate = resetDate.days(from: rollingDays)
                return currentDate >= expirationDate
            case .hours:
                // Hours isn't being handled atm because it's not included in the rule builder.
                return false
            case .none:
                return false
            }
        }
        return false
    }
    // swiftlint: enable cyclomatic_complexity

    /// Reports whether or not the budget has been exceeded for a Paywall rule, with consideration for the given date.
    /// - parameter contentID: The unique identifier for the content being evaluated.
    /// - parameter paywallRule: The Paywall rule for the budget that is being checked.
    /// - parameter countTowardsBudget: Indicates whether the page data should be added to the list of viewed pages, incrementing the budget counter.
    /// - parameter readDate: The date for when the budget should be checked. For example, when the budget resets on a specific date, this date parameter provides
    /// - returns: A tuple with a boolean indicating whether the user can view the content, and the user rule related to the provided Paywall rule.
    private static func evaluateBudget(for paywallRule: PaywallRule,
                                       contentID: String,
                                       countTowardsBudget: Bool,
                                       readDate: Date) -> (viewingContentAllowed: Bool, userRule: UserRules.UserRule) {

        // Get or create the user rule related to the provided Paywall rule.
        var userRule: UserRules.UserRule
        if !PaywallCacheManager.userRules.rules.isEmpty,
           let cachedRule = PaywallCacheManager.userRules.rules[paywallRule.id] {
            userRule = cachedRule
        } else {
            userRule = UserRules.UserRule(budget: paywallRule.maxPageViews, lastResetDate: readDate)
        }

        // Check if the page has already been viewed.
        let pageAlreadyViewed = userRule.viewedPages.contains { $0 == contentID }
        if pageAlreadyViewed {
            // The page has already been viewed and the budget does not need to be updated.
            return (viewingContentAllowed: true, userRule)
        }

        // Check if the rolling budget reset date has been reached.
        if dateExceeded(paywallRule: paywallRule, userRule: userRule, dateRead: readDate) {
            // Reset date has been reached. Reset budget counter.
            userRule.counter = 0
        }

        // Check if budget is exceeded.
        if userRule.budgetLimitMet {
            // Budget is exceeded, report viewing not allowed.
            return (false, userRule)
        }

        // Check if this evaluation should also count the page view, incrementing the cached budget counter and viewed pages.
        if countTowardsBudget {
            userRule.counter += 1
            userRule.viewedPages.append(contentID)
        }

        PaywallCacheManager.cache(rule: userRule, withID: paywallRule.id)
        return (true, userRule)
    }
}
