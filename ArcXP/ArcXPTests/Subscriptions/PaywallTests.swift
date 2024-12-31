//
//  PaywallTests.swift
//  ExampleTests
//
//  Created by David Seitz Jr on 7/23/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class PaywallTests: SubscriptionsMockNetworkTest {

    // MARK: - Convenience Types

    /// A bare bones data structure containing the data that would be provided by the Paywall backend.
    private typealias PaywallTestData = (paywallEntitlements: [String]?,
                                         paywallRuleID: Int,
                                         paywallRuleInConditions: [String: [String]]?,
                                         paywallRuleOutConditions: [String: [String]]?,
                                         paywallRuleBudgetLimit: Int)

    /// A container of all the data ponts used by ``PaywallEvaluator`` for evaluating whether a user should be able to view content or not.
    private typealias EvaluationTestData = (entitlements: [EntitlementResponseSKU]?,
                                            paywallRule: PaywallRule,
                                            conditions: [String: String]?,
                                            numberOfViews: Int)
    // MARK: - Setup

    override func setUp() {
        super.setUp()
        PaywallCacheManager.clearPaywallCache()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Tests for high level functionality

    /// Test Case 2 - Page view budget not exceeded
    ///
    /// Conditions:
    /// 1. User entitlements does not match any (at least 1) of the rule entitlements
    /// 2. Paywall conditions and client conditions match.
    /// 3. Cache budget for rule is not exceeded
    /// 4. Expected result: success
    func testPaywallPageViewBudgetNotExceeded() {

        // Create test data
        let paywallRuleTestData: PaywallTestData = (paywallEntitlements: nil,
                                                    paywallRuleID: 2,
                                                    paywallRuleInConditions: ["contentType": ["story", "video"], "deviceType": ["mobile"]],
                                                    paywallRuleOutConditions: nil,
                                                    paywallRuleBudgetLimit: 3)
        let testData = createTestData(userEntitlements: nil,
                                      paywallTestData: paywallRuleTestData,
                                      clientConditions: ["contentType": "story", "deviceType": "mobile"],
                                      numberOfViews: 2)

        // Loop through each view and verify that all views are allowed.
        var result: PaywallEvaluator.EvaluationResult
        for i in 0...testData.numberOfViews {
            result = PaywallEvaluator.evaluate(userEntitlements: nil,
                                               paywallRule: testData.paywallRule,
                                               contentID: "C2V\(i)", // content 2, view <number>
                                               conditions: testData.conditions,
                                               countTowardsBudget: true)
            let viewingContentAllowed = parseEvaluationResult(result)
            XCTAssertTrue(viewingContentAllowed)
        }
    }

    /// Test Case 3 - No matching conditions
    ///
    /// Conditions:
    /// 1. User entitlements does not match any (at least 1) of the rule entitlements
    /// 2. Paywall conditions and client conditions do not match.
    /// 3. Expected result: success
    func testPaywallNoMatchingConditions() {

        // Create test data
        let paywallRuleTestData: PaywallTestData = (paywallEntitlements: nil,
                                                    paywallRuleID: 3,
                                                    paywallRuleInConditions: ["contentType": ["video"], "deviceType": ["web"]],
                                                    paywallRuleOutConditions: nil,
                                                    paywallRuleBudgetLimit: 1)
        let testData = createTestData(userEntitlements: nil,
                                      paywallTestData: paywallRuleTestData,
                                      clientConditions: ["contentType": "story", "deviceType": "mobile"],
                                      numberOfViews: 1)
        // Evaluate data
        let result = PaywallEvaluator.evaluate(userEntitlements: nil,
                                               paywallRule: testData.paywallRule,
                                               contentID: "Content3",
                                               conditions: testData.conditions,
                                               countTowardsBudget: true)
        let viewingContentAllowed = parseEvaluationResult(result)
        XCTAssertTrue(viewingContentAllowed)
    }

    /// Test Case 4 - Page view budget exceeded
    ///
    /// Conditions:
    /// 1. User entitlements does not match any (at least 1) of the rule entitlements
    /// 2. Paywall and client conditions match.
    /// 3. Cache budget is exceeded
    /// 4. Expected result: failure
    func testPaywallPageViewBudgetExceeded() {

        // Create test data
        let paywallRuleTestData: PaywallTestData = (paywallEntitlements: nil,
                                                    paywallRuleID: 4,
                                                    paywallRuleInConditions: ["contentType": ["story", "video"], "deviceType": ["mobile"]],
                                                    paywallRuleOutConditions: nil,
                                                    paywallRuleBudgetLimit: 5)
        let testData = createTestData(userEntitlements: nil,
                                      paywallTestData: paywallRuleTestData,
                                      clientConditions: ["contentType": "story", "deviceType": "mobile"],
                                      numberOfViews: 6)

        // Loop through each page view and verify that all views are allowed.
        var viewingContentAllowed = true
        for i in 0...testData.numberOfViews {
            let result = PaywallEvaluator.evaluate(userEntitlements: nil,
                                                   paywallRule: testData.paywallRule,
                                                   contentID: "C4V\(i)", // content 4, view <number>
                                                   conditions: testData.conditions,
                                                   countTowardsBudget: true)
            // The last result should have exceeded the budget, and caused no viewing content allowed.
            viewingContentAllowed = parseEvaluationResult(result)
        }
        XCTAssertFalse(viewingContentAllowed)
    }

    /// Test Case 5 - Budget not exceeded for out conditions
    ///
    /// Conditions:
    /// 1. User entitlements does not match any of the rule entitlements
    /// 2. Paywall conditions and client conditions match, but Paywall condition is out (excempting the view from being metered).
    /// 3. Rule budget increments for other condition values (mobile out, others increment), but does not exceed the budget
    /// 4. Expected result: success
    func testPaywallBudgetNotExceededForOutConditions() {

        // Create test data
        let paywallTestData: PaywallTestData = (paywallEntitlements: nil,
                                                paywallRuleID: 5,
                                                paywallRuleInConditions: nil,
                                                paywallRuleOutConditions: ["deviceType": ["mobile"]],
                                                paywallRuleBudgetLimit: 2)
        let testData = createTestData(userEntitlements: nil,
                                      paywallTestData: paywallTestData,
                                      clientConditions: ["devicetype": "mobile"],
                                      numberOfViews: 1)
        // Evaluate data
        for i in 0...testData.numberOfViews {
            let result = PaywallEvaluator.evaluate(userEntitlements: nil,
                                                   paywallRule: testData.paywallRule,
                                                   contentID: "C5V\(i)", // content 5, view <number>
                                                   conditions: testData.conditions,
                                                   countTowardsBudget: true)
            let viewingContentAllowed = parseEvaluationResult(result)
            XCTAssertTrue(viewingContentAllowed)
        }
    }

    func testRuleBudget() {

        XCTAssertEqual(RuleBudget.WeekdayType.sunday.toDateComponentDay(), 1)
        XCTAssertEqual(RuleBudget.WeekdayType.monday.toDateComponentDay(), 2)
        XCTAssertEqual(RuleBudget.WeekdayType.tuesday.toDateComponentDay(), 3)
        XCTAssertEqual(RuleBudget.WeekdayType.wednesday.toDateComponentDay(), 4)
        XCTAssertEqual(RuleBudget.WeekdayType.thursday.toDateComponentDay(), 5)
        XCTAssertEqual(RuleBudget.WeekdayType.friday.toDateComponentDay(), 6)
        XCTAssertEqual(RuleBudget.WeekdayType.saturday.toDateComponentDay(), 7)

        let dates = [RuleBudget.WeekdayType.date(for: .sunday, immediatelyFollowing: Date()),
                     RuleBudget.WeekdayType.date(for: .monday, immediatelyFollowing: Date()),
                     RuleBudget.WeekdayType.date(for: .tuesday, immediatelyFollowing: Date()),
                     RuleBudget.WeekdayType.date(for: .wednesday, immediatelyFollowing: Date()),
                     RuleBudget.WeekdayType.date(for: .thursday, immediatelyFollowing: Date()),
                     RuleBudget.WeekdayType.date(for: .friday, immediatelyFollowing: Date()),
                     RuleBudget.WeekdayType.date(for: .saturday, immediatelyFollowing: Date())]
        for date in dates { XCTAssertNotNil(date) }

        let nilDates = [RuleBudget.WeekdayType.date(for: nil, immediatelyFollowing: Date()),
                        RuleBudget.WeekdayType.date(for: nil, immediatelyFollowing: Date().days(from: 1)),
                        RuleBudget.WeekdayType.date(for: nil, immediatelyFollowing: Date().days(from: 2)),
                        RuleBudget.WeekdayType.date(for: nil, immediatelyFollowing: Date().days(from: 3)),
                        RuleBudget.WeekdayType.date(for: nil, immediatelyFollowing: Date().days(from: 4)),
                        RuleBudget.WeekdayType.date(for: nil, immediatelyFollowing: Date().days(from: 5)),
                        RuleBudget.WeekdayType.date(for: nil, immediatelyFollowing: Date().days(from: 6))]

        for nilDate in nilDates {
            XCTAssertNil(nilDate)
        }
    }

    func testPaywallEntitlement() {
        let entitlementString = PaywallEntitlmentValue.string("premium")
        let entitlementBool = PaywallEntitlmentValue.bool(true)
        XCTAssertNotNil(entitlementString)
        XCTAssertNotNil(entitlementBool)
        let jsonEncoder = JSONEncoder()
        let entitlementStringData = try? jsonEncoder.encode(entitlementString)
        let entitlementBoolData = try? jsonEncoder.encode(entitlementBool)
        XCTAssertNotNil(entitlementStringData)
        XCTAssertNotNil(entitlementBoolData)
        guard let encodedEntitlementString = entitlementStringData,
              let encodedEntitlementBool = entitlementBoolData else {
            XCTFail()
            return
        }
        let jsonDecoder = JSONDecoder()
        let decodedEntitlementString = try? jsonDecoder.decode(PaywallEntitlmentValue.self, from: encodedEntitlementString)
        let decodedEntitlementBool = try? jsonDecoder.decode(PaywallEntitlmentValue.self, from: encodedEntitlementBool)
        XCTAssertNotNil(decodedEntitlementString)
        XCTAssertNotNil(decodedEntitlementBool)
    }

    // MARK: - Convenience Methods

    /// Taker all the essential data provided in these function parameters, and create test data to be used in the Paywall algorithm.
    /// - returns: A convenient tuple containing each of the required parameters for testing the Paywall algorithm.
    private func createTestData(userEntitlements userEntitlementStrings: [String]?,
                                paywallTestData: PaywallTestData,
                                clientConditions: [String: String]?,
                                numberOfViews: Int) -> EvaluationTestData {

        // Create entitlements
        var parsedUserEntitlements: [EntitlementResponseSKU]?
        if let userEntitlementStrings = userEntitlementStrings {
            var userEntitlements = [EntitlementResponseSKU]()
            for string in userEntitlementStrings {
                let userEntitlement = EntitlementResponseSKU(sku: string)
                userEntitlements.append(userEntitlement)
            }
            parsedUserEntitlements = userEntitlements
        }

        // Create Paywall Rule Conditions
        var parsedRuleConditions = [String: RuleCondition]()
        paywallTestData.paywallRuleInConditions?.forEach({ paywallRuleInCondition in
            let ruleConditionValues = RuleCondition(isIn: true, values: paywallRuleInCondition.value)
            parsedRuleConditions[paywallRuleInCondition.key] = ruleConditionValues
        })
        paywallTestData.paywallRuleOutConditions?.forEach({ paywallRuleOutCondition in
            let ruleConditionValues = RuleCondition(isIn: false, values: paywallRuleOutCondition.value)
            parsedRuleConditions[paywallRuleOutCondition.key] = ruleConditionValues
        })

        // Create Paywall Rule Budget
        let ruleBudget = RuleBudget(budgetType: .rolling,
                                    calendarType: nil,
                                    calendarWeekday: nil,
                                    rollingType: nil,
                                    rollingDays: 7)
        // Create Paywall Rule
        var paywallEntitlements: [PaywallEntitlmentValue]?
        if let entitlements = paywallTestData.paywallEntitlements {
            var parsedEntitlements = [PaywallEntitlmentValue]()
            for entitlementString in entitlements {
                let paywallEntitlement = PaywallEntitlmentValue.string(entitlementString)
                parsedEntitlements.append(paywallEntitlement)
            }
            if parsedEntitlements.count > 0 { paywallEntitlements = parsedEntitlements }
        }

        let parsedPaywallRule = PaywallRule(id: paywallTestData.paywallRuleID,
                                            conditions: parsedRuleConditions,
                                            budget: ruleBudget,
                                            entitlementsSKUs: paywallEntitlements, 
                                            entitlementsZones: nil,
                                            campaignLink: nil,
                                            maxPageViews: paywallTestData.paywallRuleBudgetLimit,
                                            campaignCode: nil)
        // Create page view data
        var pageViews = [PageViewData]()
        for i in 0...numberOfViews {
            let pageViewData = PageViewData(pageId: String(i), conditions: clientConditions ?? [String: String]())
            pageViews.append(pageViewData)
        }

        return (parsedUserEntitlements,
                parsedPaywallRule,
                clientConditions,
                numberOfViews)
    }

    /// Parse the result returned from Paywall evaluation, and report whether the result allows viewing content or not.
    /// - parameter result: The result to be parsed.
    /// - returns: A boolean indicating whether content should be viewiable or not.
    func parseEvaluationResult(_ result: PaywallEvaluator.EvaluationResult) -> Bool {
        switch result {
        case .budgetExceeded:
            return false
        default:
            return true
        }
    }

    func testPaywallErrors() {
        let noActivePaywallRules = PaywallManager.PaywallManagerError.noActivePaywallRules
        XCTAssertEqual(noActivePaywallRules.localizedDescription, "Found no active Paywall rules to evaluate against.")
        let userRules = TrippedRule(ruleId: 10, rule:  UserRules.UserRule(budget: 5, lastResetDate: Date()),
                                                                          campaignLink: "https://www.campaignLink.com")
        let ruleTripped = PaywallManager.PaywallManagerError.rulesTripped(rule: userRules)
        XCTAssertEqual(ruleTripped.localizedDescription, "Rule is tripped.")
    }

    func testEvaluationResultEquatable() {
        let userRule = UserRules.UserRule(budget: 3, lastResetDate: Date())
        let nonMatchingUserRule = UserRules.UserRule(budget: 5, lastResetDate: Date())
        XCTAssertEqual(PaywallEvaluator.EvaluationResult.budgetExceeded(rule: userRule), .budgetExceeded(rule: userRule))
        XCTAssertNotEqual(PaywallEvaluator.EvaluationResult.budgetExceeded(rule: userRule), .budgetExceeded(rule: nonMatchingUserRule))
        XCTAssertNotEqual(PaywallEvaluator.EvaluationResult.budgetExceeded(rule: userRule), .entitlementsMatch)
        XCTAssertEqual(PaywallEvaluator.EvaluationResult.entitlementsMatch, PaywallEvaluator.EvaluationResult.entitlementsMatch)
        XCTAssertEqual(PaywallEvaluator.EvaluationResult.conditionsDontMatch, PaywallEvaluator.EvaluationResult.conditionsDontMatch)
    }

    // MARK: - Condition Matching
    // These tests compare Page View Data conditions with Paywall conditions.
    // Page View Data conditions help to decide who can and can't view content, per each page, or content item.

    private func createPaywallRule(withConditions conditions: [String: RuleCondition]) -> PaywallRule {
        let ruleBudget = RuleBudget(budgetType: .calendar,
                                    calendarType: .monthly,
                                    calendarWeekday: nil,
                                    rollingType: nil,
                                    rollingDays: nil)
        return PaywallRule(id: 1,
                           conditions: conditions,
                           budget: ruleBudget,
                           entitlementsSKUs: nil, 
                           entitlementsZones: nil,
                           campaignLink: nil,
                           maxPageViews: 5,
                           campaignCode: nil)
    }

    private func createRuleConditions(conditions: [(condition: String, values: [String], isIn: Bool)]) -> [String: RuleCondition] {
        var ruleConditions = [String: RuleCondition]()
        for item in conditions {
            let condition = RuleCondition(isIn: item.isIn, values: item.values)
            ruleConditions[item.condition] = condition
        }
        return ruleConditions
    }

    // MARK: Tests

    func testConditionMatchIsInTrue() {
        let ruleConditions = createRuleConditions(conditions: [("Condition1", ["Value1"], true)])
        let pageConditions = ["Condition1": "Value1"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertEqual(conditionsAndValuesMatch, true)
    }

    func testConditionMatchIsInFalse() {
        let ruleConditions = createRuleConditions(conditions: [("Condition1", ["Value1"], false)])
        let pageConditions = ["Condition1": "Value1"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertEqual(conditionsAndValuesMatch, false)
    }

    // Condition does not match and isIn is false
    func testConditionDontMatchIsInFalse() {
        let ruleConditions = createRuleConditions(conditions: [("Condition1", ["Value1"], false)])
        let pageConditions = ["Condition2": "Value2"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertEqual(conditionsAndValuesMatch, true)
    }
    
    // evaluate conditions one rule condition one page condition pass
    func testPageAndRuleConditionsMatch() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile"], true)])
        let pageConditions = ["deviceClass": "mobile"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertTrue(conditionsAndValuesMatch)
    }
    
    func testPageAndRuleConditionsMatch2() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile"], true)])
        let pageConditions:[String:String] = [:]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertTrue(conditionsAndValuesMatch)
    }
    
    // evaluate conditions two rule conditions two page conditions pass
    func testPageConditionAndTwoRuleConditionsMatch() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile"], true), 
                                                               ("contentType", ["story"], true)])
        let pageConditions:[String:String] = ["contentType": "story"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertTrue(conditionsAndValuesMatch)
    }
    
    // evaluate conditions values array CONTAINS
    func testPageAndMultipleValuesRuleConditionsMatch() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile", "web"], true)])
        let pageConditions:[String:String] = ["contentType": "story"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertTrue(conditionsAndValuesMatch)
    }
    
    // evaluate conditions values array CONTAINS rule does not apply`
    func testPageAndMultipleValuesRuleConditionsDontMatch() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile", "web"], true)])
        let pageConditions:[String:String] = ["deviceClass": "PC"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertFalse(conditionsAndValuesMatch)
    }
    
    // evaluate conditions one rule condition one page condition OUT, rule applies
    func testPageAndRuleConditionsIsOutRuleApply() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile", "web"], false)])
        let pageConditions:[String:String] = ["deviceClass": "PC"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertTrue(conditionsAndValuesMatch)
    }
    
    // evaluate conditions one rule condition one page condition OUT, rule applies
    func testPageAndRuleConditionsIsOutRuleNotApply() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile", "web"], false)])
        let pageConditions:[String:String] = ["deviceClass": "web"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertFalse(conditionsAndValuesMatch)
    }
    
    // evaluate conditions exact match all IN rule applies
    func testMultiplePageAndRuleConditionsAllMatches() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile"], true),
                                                               ("contentType", ["story"], true)])
        let pageConditions:[String:String] = ["deviceClass": "mobile", 
                                              "contentType": "story"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertTrue(conditionsAndValuesMatch)
    }
    
    // evaluate conditions partial match all IN rule applies
    func testMultiplePageAndRuleConditionsPartialMatches() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile"], true),
                                                               ("contentType", ["story"], true)])
        let pageConditions:[String:String] = ["deviceClass": "mobile"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertTrue(conditionsAndValuesMatch)
    }
    
    // evaluate conditions exact match one IN one OUT rule applies
    func testPageAndRuleConditionsExactMatchOneInOneOut() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile"], true),
                                                               ("contentType", ["story"], false)])
        let pageConditions:[String:String] = ["deviceClass": "mobile",
                                              "contentType": "gallery"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertTrue(conditionsAndValuesMatch)
    }
    
    // evaluate conditions exact match all OUT rule applies
    func testMultiplePageAndRuleConditionsMatchAllOut() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile"], false),
                                                               ("contentType", ["story"], false)])
        let pageConditions:[String:String] = ["deviceClass": "desktop",
                                              "contentType": "gallery"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertTrue(conditionsAndValuesMatch)
    }
    
    // evaluate more conditions than rules applies
    func testMorePageConditionsThanRuleConditionsApply() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile"], true),
                                                               ("contentType", ["story"], true)])
        let pageConditions:[String:String] = ["deviceClass": "mobile",
                                              "contentType": "story",
                                              "section": "business"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertTrue(conditionsAndValuesMatch)
    }
    
    // evaluate conditions more conditions than rules fails
    func testMorePageConditionsThanRuleConditionsRuleFails() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile"], true),
                                                               ("contentType", ["story"], false)])
        let pageConditions:[String:String] = ["deviceClass": "mobile",
                                              "contentType": "story",
                                              "section": "business"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertFalse(conditionsAndValuesMatch)
    }
    
    
    // evaluate conditions more rules than page conditions rule applies
    func testMoreRuleConditionsThanPageConditionsApply() {
        let ruleConditions = createRuleConditions(conditions: [("deviceClass", ["mobile"], true),
                                                               ("contentType", ["story"], true),
                                                               ("section", ["business"], true)])
        let pageConditions:[String:String] = ["deviceClass": "mobile",
                                              "contentType": "story"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertTrue(conditionsAndValuesMatch)
    }

    // Condition does not match and isIn is true
    func testConditionDontMatchIsInTrue() {
        let ruleConditions = createRuleConditions(conditions: [("Condition1", ["Value1"], true)])
        let pageConditions = ["Condition2": "Value2"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertEqual(conditionsAndValuesMatch, true)
    }

    func testMatchingConditionDifferentValueIsOut() {
        let ruleConditions = createRuleConditions(conditions: [("Condition1", ["Value1"], false)])
        let pageConditions = ["Condition1": "Value2"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertEqual(conditionsAndValuesMatch, true)
    }

    func testMatchingConditionDifferentValueIsIn() {
        let ruleConditions = createRuleConditions(conditions: [("Condition1", ["Value1"], true)])
        let pageConditions = ["Condition1": "Value2"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertEqual(conditionsAndValuesMatch, false)
    }

    func testConditionsCountMismatchMorePageViewConditions() {
        let ruleConditions = createRuleConditions(conditions: [("Condition1", ["Value1"], false)])
        let pageConditions = ["Condition1": "Value1", "Condition2": "Value2"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertEqual(conditionsAndValuesMatch, false)
    }

    func testConditionsCountMismatchMorePaywallConditions() {
        let simpleRuleConditions = [("Condition1", ["Value1"], true),
                                    ("Condition2", ["Value2"], true)]
        let ruleConditions = createRuleConditions(conditions: simpleRuleConditions)
        let pageConditions = ["Condition1": "Value1"]
        let conditionsAndValuesMatch = PaywallEvaluator.evaluatePageConditions(ruleConditions: ruleConditions,
                                                                           pageConditions: pageConditions)
        XCTAssertEqual(conditionsAndValuesMatch, true)
    }
    
    func testGeoLocationsAllInSuccess() {
        let ruleConditions = createRuleConditions(conditions: [("city", ["DC"], true),
                                                               ("continent", ["NorthAmerica"], true),
                                                               ("georegion", ["NorthAmerica"], true),
                                                               ("dma", ["dma"], true),
                                                               ("country_code", ["USA"], true)])
        let edgeScape = Edgescape(city: "DC", continent: "NorthAmerica", geoRegion: "NorthAmerica", dma: "dma", countryCode: "USA")
        
        let result = PaywallEvaluator.evaluateGeoLocations(ruleConditions: ruleConditions, geoConditions: edgeScape)
        XCTAssertTrue(result)
    }
    
    func testGeoLocations2diffGeoKeysSuccess() {
        let ruleConditions = createRuleConditions(conditions: [("city", ["DC"], true),
                                                               ("state", ["DC"], true),
                                                               ("county", ["Marion"], true),
                                                               ("dma", ["dma"], true),
                                                               ("country_code", ["USA"], true)])
        let edgeScape = Edgescape(city: "DC", continent: "NorthAmerica", geoRegion: "NorthAmerica", dma: "dma", countryCode: "USA")
        
        let result = PaywallEvaluator.evaluateGeoLocations(ruleConditions: ruleConditions, geoConditions: edgeScape)
        XCTAssertTrue(result)
    }
    
    func testGeoLocations2UnMatchingInFailure() {
        let ruleConditions = createRuleConditions(conditions: [("city", ["UNMATCHED"], true),
                                                               ("continent", ["UNMATCHED"], true),
                                                               ("georegion", ["NorthAmerica"], true),
                                                               ("dma", ["dma"], true),
                                                               ("country_code", ["USA"], true)])
        let edgeScape = Edgescape(city: "DC", continent: "NorthAmerica", geoRegion: "NorthAmerica", dma: "dma", countryCode: "USA")
        
        let result = PaywallEvaluator.evaluateGeoLocations(ruleConditions: ruleConditions, geoConditions: edgeScape)
        XCTAssertFalse(result)
    }
    
    
    func testGeoLocationsCityOutFailure() {
        let ruleConditions = createRuleConditions(conditions: [("city", ["DC"], false),
                                                               ("continent", ["NorthAmerica"], true),
                                                               ("georegion", ["NorthAmerica"], true),
                                                               ("dma", ["dma"], true),
                                                               ("country_code", ["USA"], true)])
        let edgeScape = Edgescape(city: "DC", continent: "NorthAmerica", geoRegion: "NorthAmerica", dma: "dma", countryCode: "USA")
        
        let result = PaywallEvaluator.evaluateGeoLocations(ruleConditions: ruleConditions, geoConditions: edgeScape)
        XCTAssertFalse(result)
    }
    
    
    func testGeoLocationsAllOutFailure() {
        let ruleConditions = createRuleConditions(conditions: [("city", ["DC"], false),
                                                               ("continent", ["NorthAmerica"], false),
                                                               ("georegion", ["NorthAmerica"], false),
                                                               ("dma", ["dma"], false),
                                                               ("country_code", ["USA"], false)])
        let edgeScape = Edgescape(city: "DC", continent: "NorthAmerica", geoRegion: "NorthAmerica", dma: "dma", countryCode: "USA")
        
        let result = PaywallEvaluator.evaluateGeoLocations(ruleConditions: ruleConditions, geoConditions: edgeScape)
        XCTAssertFalse(result)
    }
    
    func testGeoLocationsAllOutSuccess() {
        let ruleConditions = createRuleConditions(conditions: [("city", ["DC"], false),
                                                               ("continent", ["NorthAmerica"], false),
                                                               ("georegion", ["NorthAmerica"], false),
                                                               ("dma", ["dma"], false),
                                                               ("country_code", ["USA"], false)])
        let edgeScape = Edgescape(city: "DC1", continent: "NorthAmerica1", geoRegion: "NorthAmerica1", dma: "dma1", countryCode: "USA1")
        
        let result = PaywallEvaluator.evaluateGeoLocations(ruleConditions: ruleConditions, geoConditions: edgeScape)
        XCTAssertTrue(result)
    }
    
    func testGeoLocations2GeoKeysDiffOutSuccess() {
        let ruleConditions = createRuleConditions(conditions: [("city", ["DC"], false),
                                                               ("state", ["NorthAmerica"], false),
                                                               ("county", ["NorthAmerica"], false),
                                                               ("dma", ["dma"], false),
                                                               ("country_code", ["USA"], false)])
        let edgeScape = Edgescape(city: "DC1", continent: "NorthAmerica", geoRegion: "NorthAmerica", dma: "dma1", countryCode: "USA1")
        
        let result = PaywallEvaluator.evaluateGeoLocations(ruleConditions: ruleConditions, geoConditions: edgeScape)
        XCTAssertTrue(result)
    }
    
    func testGeoLocationWithPaywallRuleConditionsDontMatch() {
        let paywallRule = PaywallRule(
            id: 1,
            conditions:  createRuleConditions(conditions: [("city", ["NYC"], false),
                                                           ("continent", ["NorthAmerica"], false),
                                                           ("georegion", ["NorthAmerica"], false),
                                                           ("dma", ["dma"], false),
                                                           ("country_code", ["USA"], false)]),
            budget: RuleBudget(
                budgetType: .calendar,
                calendarType: .monthly,
                calendarWeekday: nil,
                rollingType: nil,
                rollingDays: nil
            ),
            entitlementsSKUs: [.string("accessToExclusiveContent"), .bool(true)],
            entitlementsZones: nil,
            campaignLink: "https://example.com/campaign1",
            maxPageViews: 5,
            campaignCode: "SPRING_SALE"
        )
        
        // Setup user entitlements with edgescape not matching with rule conditions. Here city is mismatch.
        let userEntitlements = EntitlementsResponse(skus: nil,
                                                    zones: nil,
                                                    edgescape: Edgescape(city: "DC", continent: "NorthAmerica", geoRegion: "NorthAmerica", dma: "dma", countryCode: "USA"))
        //
        let result = PaywallEvaluator.evaluate(userEntitlements: userEntitlements,
                                               paywallRule: paywallRule,
                                               contentID: "ID",
                                               conditions: nil,
                                               countTowardsBudget: true)
        
        XCTAssertEqual(result, .conditionsDontMatch)
    }
    
    

    // MARK: - General Paywall Tests

    func testLoadentitlementsSuccess() {
        let expectation = prepareSubscriptionsNetworkExpectatation(with: "Successfully load entitlements.",
                                                                   result: .success,
                                                                   statusCode: 200,
                                                                   endpoint: SalesEndpoint.entitlements)
        PaywallManager.loadEntitlements { result in
            switch result {
            case .success:
                XCTAssertNotNil(PaywallManager.entitlementResponse)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Unexpectedly failed to load entitlements with error. Error: \(error.localizedDescription)")
            }
        }
        wait(for: [expectation], timeout: TestConstant.expectationTimeout)
    }

    func testLoadPaywallRulesWithUserRulesSuccess() {
        let expectation = prepareSubscriptionsNetworkExpectatation(with: "Successfully fetched Paywall Rules",
                                                                   result: .success,
                                                                   statusCode: 200,
                                                                   endpoint: RetailEndpoint.paywall)
        PaywallManager.loadPaywallRulesWithUserRules { result in
            switch result {
            case .success:
                XCTAssertNotNil(PaywallManager.activePaywallRules)
                expectation.fulfill()
                break
            case .failure(let error):
                XCTFail("Error occurred while testing successful Paywall rules fetch. Error: \(error.localizedDescription)")
            }
        }
        wait(for: [expectation], timeout: TestConstant.expectationTimeout)
    }

    func testLoadV2PaywallRulesWithUserRulesSuccess() {
        let originalMockVersion = Subscriptions.mock.version
        let expectation = prepareSubscriptionsNetworkExpectatation(with: "Successfully fetched Paywall Rules",
                                                                   result: .success,
                                                                   statusCode: 200,
                                                                   endpoint: RetailEndpoint.paywall,
                                                                   version: .v2)
        PaywallManager.loadPaywallRulesWithUserRules { result in
            switch result {
            case .success:
                XCTAssertNotNil(PaywallManager.activePaywallRules)
                expectation.fulfill()
                break
            case .failure(let error):
                XCTFail("Error occurred while testing successful Paywall rules fetch. Error: \(error.localizedDescription)")
            }
            Subscriptions.mock.version = originalMockVersion
        }
        wait(for: [expectation], timeout: TestConstant.expectationTimeout)
    }

    func testEvaluateSuccessWithValidBudget() {
        PaywallManager.activePaywallRules = mockPayWallRules(budget1: 5, budget2: 10)
        let result = PaywallManager.evaluate(contentID: "1234", countTowardsBudget: false)
        switch result {
        case .success():
            XCTAssertTrue(true)
        case .failure(let error):
            XCTFail("Unexpectedly failed Paywall evaluation with error: \(error.localizedDescription)")
        }
    }
    
    func testEvaluationFailureNoActivePaywallRules() {
        PaywallManager.activePaywallRules = nil
        let result = PaywallManager.evaluate(contentID: "1234", countTowardsBudget: true)
        switch result {
        case .success:
            XCTFail("Unexpectedly recieved a successful result from Paywall evluation.")
        case .failure(let error):
            XCTAssertEqual(error.localizedDescription, "Found no active Paywall rules to evaluate against.")
        }
    }
    
    // Setting budget to 0 will cause the rule to trip
    func testEvaluateFailureWithBudgetExceededForMockRule1() {
        PaywallManager.activePaywallRules = mockPayWallRules(budget1: 0, budget2: 5)
        let result = PaywallManager.evaluate(contentID: "1234", countTowardsBudget: false)
        switch result {
        case .success():
            XCTFail("Unexpectedly recieved a successful result from Paywall evluation.")
        case .failure(let trippedRule):
            XCTAssertNotNil(trippedRule)
            switch trippedRule {
            case .rulesTripped(rule: let trippedRule):
                XCTAssertEqual(trippedRule?.ruleId, 1);
                XCTAssertEqual(trippedRule?.rule.budget, 0)
                XCTAssertEqual(trippedRule?.campaignLink, "https://example.com/campaign1")
            default:
                XCTFail("Unexpected error type.")
            }
        }
    }
    
    // Setting budget to 0 will cause the rule to trip
    func testEvaluateFailureWithBudgetExceededForMockRule2() {
        PaywallManager.activePaywallRules = mockPayWallRules(budget1: 5, budget2: 0)
        let result = PaywallManager.evaluate(contentID: "1234", countTowardsBudget: false)
        switch result {
        case .success():
            XCTFail("Unexpectedly recieved a successful result from Paywall evluation.")
        case .failure(let trippedRule):
            XCTAssertNotNil(trippedRule)
            switch trippedRule {
            case .rulesTripped(rule: let trippedRule):
                XCTAssertEqual(trippedRule?.ruleId, 2);
                XCTAssertEqual(trippedRule?.rule.budget, 0)
                XCTAssertEqual(trippedRule?.campaignLink, "https://example.com/campaign2")
            default:
                XCTFail("Unexpected error type.")
            }
        }
    }

    func testReadDateNotExceededResetMonthAndReadLimitReached() {
        // Rulebudget is set to monthly rest
        let ruleBudget = RuleBudget(budgetType: .calendar,
                                    calendarType: .monthly,
                                    calendarWeekday: nil,
                                    rollingType: nil,
                                    rollingDays: nil)

        // Setup paywall rules with a matching SKU entitlement
        let rule = PaywallRule(id: 1,
                               conditions: [:],
                               budget: ruleBudget,
                               entitlementsSKUs: [.bool(true), .string("UnitTestSKU1")],
                               entitlementsZones: [.bool(false)],
                               campaignLink: nil,
                               maxPageViews: 1,
                               campaignCode: nil)
        // Cache the userRule with budget 1 and counter 1 which means it's read
        let userRule = UserRules.UserRule(budget: 1, lastResetDate: Date())
        userRule.counter = 1
        PaywallCacheManager.cache(rule: userRule, withID: rule.id)
        // Read date is within the same month
        let result = PaywallEvaluator.evaluate(userEntitlements: nil,
                                               paywallRule: rule,
                                               contentID: "ID",
                                               conditions: nil,
                                               countTowardsBudget: true,
                                               readDate: Date())
        PaywallCacheManager.clearPaywallCache()
        XCTAssertEqual(PaywallEvaluator.EvaluationResult.budgetExceeded(rule: userRule), result)
    }

    func testReadDateExceededResetMonth() {
        // Rulebudget is set to monthly rest
        let ruleBudget = RuleBudget(budgetType: .calendar,
                                    calendarType: .monthly,
                                    calendarWeekday: nil,
                                    rollingType: nil,
                                    rollingDays: nil)

        let rule = PaywallRule(id: 1,
                               conditions: [:],
                               budget: ruleBudget,
                               entitlementsSKUs: [.bool(true), .string("UnitTestSKU1")],
                               entitlementsZones: [.bool(false)],
                               campaignLink: nil,
                               maxPageViews: 1,
                               campaignCode: nil)
        // Cache the userRule with budget 1 and counter 1 which means it's read
        let userRule = UserRules.UserRule(budget: 1, lastResetDate: Date())
        userRule.counter = 1
        PaywallCacheManager.cache(rule: userRule, withID: rule.id)
        // Read date is 70 days from the current date
        let result = PaywallEvaluator.evaluate(userEntitlements: nil,
                                               paywallRule: rule,
                                               contentID: "ID",
                                               conditions: nil,
                                               countTowardsBudget: true,
                                               readDate: Date().days(from: 70))
        PaywallCacheManager.clearPaywallCache()
        // Here the counter will be reset to 0 since the readDate is 70 days from the current date
        if case .budgetExceeded(rule: let rule) = result {
            XCTAssertEqual(rule.counter, 0)
        }
    }

    // MARK: - Entitlements Fetching and Parsing

    func testFetchEntitlementsV1() {
        let expectation = prepareSubscriptionsNetworkExpectatation(with: "Successfully fetch user entitlements.",
                                                                   result: .success,
                                                                   statusCode: 200,
                                                                   endpoint: SalesEndpoint.entitlements)
        Subscriptions.Sales.fetchEntitlements { result in
            switch result {
            case .success(let entitlementsResponse):
                guard let skus = entitlementsResponse.skus,
                      let edgescape = entitlementsResponse.edgescape else {
                    XCTFail("Entitlements response did not contain expected values.")
                    return
                }
                XCTAssertNil(entitlementsResponse.zones) // Should not be present in v1
                XCTAssertEqual(skus[0].sku, "123456")
                XCTAssertEqual(skus[1].sku, "33333")
                XCTAssertEqual(edgescape.city, "CHICAGO")
                XCTAssertEqual(edgescape.continent, "NA")
                XCTAssertEqual(edgescape.geoRegion, "255")
                XCTAssertEqual(edgescape.dma, "602")
                XCTAssertEqual(edgescape.countryCode, "US")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to fetch mock v1 entitlements with error: \(error.localizedDescription)")
            }
        }
        wait(for: [expectation], timeout: TestConstant.expectationTimeout)
    }

    func testFetchEntitlementsV2() {
        let expectation = prepareSubscriptionsNetworkExpectatation(with: "Successfully fetch user entitlements.",
                                                                   result: .success,
                                                                   statusCode: 200,
                                                                   endpoint: SalesEndpoint.entitlements,
                                                                   version: .v2)
        Subscriptions.Sales.fetchEntitlements { result in
            switch result {
            case .success(let entitlementsResponse):
                guard let zones = entitlementsResponse.zones,
                      let edgescape = entitlementsResponse.edgescape else {
                    XCTFail("Did not contain expected values for v2 entitlements response.")
                    return
                }
                XCTAssertNil(entitlementsResponse.skus) // Should not be present in v2
                XCTAssertEqual(zones.count, 6)
                XCTAssertEqual(zones[0], 1)
                XCTAssertEqual(zones[5], 6)
                XCTAssertEqual(edgescape.city, "BOGOTA")
                XCTAssertEqual(edgescape.continent, "SA")
                XCTAssertEqual(edgescape.geoRegion, "50")
                XCTAssertNil(edgescape.dma)
                XCTAssertEqual(edgescape.countryCode, "CO")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to fetch mock v2 entitlements with error: \(error.localizedDescription)")
            }
        }
        wait(for: [expectation], timeout: TestConstant.expectationTimeout)
    }

    // MARK: Entitlements Matching

    /// Test no zones, registere
    func testV1NoSKUsRegisteredUser() {
        // e: [true] ent: [false] means the rule will be bypassed by a registered user

        // Setup user entitlements without specifying SKUs or zones, indicating a registered user
        let userEntitlements = EntitlementsResponse(skus: nil,
                                                    zones: nil,
                                                    edgescape: nil)

        let ruleBudget = RuleBudget(budgetType: .calendar, 
                                    calendarType: nil,
                                    calendarWeekday: nil,
                                    rollingType: nil,
                                    rollingDays: nil)

        // Setup a paywall rule that allows access for registered users
        let rule = PaywallRule(id: 1, 
                               conditions: [:],
                               budget: ruleBudget,
                               entitlementsSKUs: [.bool(true)],
                               entitlementsZones: [.bool(false)],
                               campaignLink: nil,
                               maxPageViews: 100,
                               campaignCode: nil)

        // Ensure an access token is available to indicate a "registered user" is logged in
        let originalAccessToken = Subscriptions.Identity.accessToken
        Subscriptions.Identity.accessToken = TestConstant.mockAccessToken

        // Check for entitlement match
        let result = PaywallEvaluator.evaluateEntitlements(userEntitlements: userEntitlements, paywallRules: [rule])

        // Assert that the result is true, meaning the rule is bypassed for registered users
        XCTAssertFalse(result, "Registered user should bypass the rule.")

        // Restore original access token value
        Subscriptions.Identity.accessToken = originalAccessToken
    }

    func testV1SKUMatchesAndTrue() {
        // e: [true, 'SKU1'] ent: [false] means the rule will be bypassed by a user with “SKU1”
        // Setup user entitlements with a specific SKU
        let userEntitlements = EntitlementsResponse(skus: [EntitlementResponseSKU(sku: "UnitTestSKU1")],
                                                    zones: nil,
                                                    edgescape: nil)

        let ruleBudget = RuleBudget(budgetType: .calendar,
                                    calendarType: nil,
                                    calendarWeekday: nil,
                                    rollingType: nil,
                                    rollingDays: nil)

        // Setup paywall rules with a matching SKU entitlement
        let rule = PaywallRule(id: 1,
                               conditions: [:],
                               budget: ruleBudget,
                               entitlementsSKUs: [.bool(true), .string("UnitTestSKU1")],
                               entitlementsZones: [.bool(false)],
                               campaignLink: nil,
                               maxPageViews: 1,
                               campaignCode: nil)

        // Check for entitlement match
        let result = PaywallEvaluator.evaluateEntitlements(userEntitlements: userEntitlements, paywallRules: [rule])

        // Assert that the result is true, indicating a direct SKU match
        XCTAssertFalse(result, "User with matching SKU should bypass the rule.")
    }

    func testV2ZonesMatch() {
        // e: [false] ent: [true, 123] means the rule will be bypassed by a user with the entitlement 123

        // Setup user entitlements with specific zones
        let userEntitlements = EntitlementsResponse(skus: nil, zones: [123, 234, 345], edgescape: nil)

        let ruleBudget = RuleBudget(budgetType: .calendar, 
                                    calendarType: nil,
                                    calendarWeekday: nil,
                                    rollingType: nil,
                                    rollingDays: nil)

        // Setup paywall rules with a matching zone entitlement
        let rule = PaywallRule(id: 3, 
                               conditions: [:],
                               budget: ruleBudget,
                               entitlementsSKUs: [.bool(false)],
                               entitlementsZones: [.bool(true), .int(123)],
                               campaignLink: nil,
                               maxPageViews: 100,
                               campaignCode: nil)

        // Check for entitlement match
        let result = PaywallEvaluator.evaluateEntitlements(userEntitlements: userEntitlements, paywallRules: [rule])

        // Assert that the result is true, indicating a direct zone match
        XCTAssertFalse(result, "User with matching zone should bypass the rule.")
    }

    // MARK: Gracefully handle missing "e" or "ent" values from the backend.

    func testV1NoSKUsRegisteredUserNilEnt() {
        // e: [true] ent: [false] means the rule will be bypassed by a registered user

        // Setup user entitlements without specifying SKUs or zones, indicating a registered user
        let userEntitlements = EntitlementsResponse(skus: nil,
                                                    zones: nil,
                                                    edgescape: nil)

        let ruleBudget = RuleBudget(budgetType: .calendar,
                                    calendarType: nil,
                                    calendarWeekday: nil,
                                    rollingType: nil,
                                    rollingDays: nil)

        // Setup a paywall rule that allows access for registered users
        let rule = PaywallRule(id: 1,
                               conditions: [:],
                               budget: ruleBudget,
                               entitlementsSKUs: [.bool(true)],
                               entitlementsZones: nil,
                               campaignLink: nil,
                               maxPageViews: 100,
                               campaignCode: nil)

        // Ensure an access token is available to indicate a "registered user" is logged in
        let originalAccessToken = Subscriptions.Identity.accessToken
        Subscriptions.Identity.accessToken = TestConstant.mockAccessToken

        // Check for entitlement match
        let result = PaywallEvaluator.evaluateEntitlements(userEntitlements: userEntitlements, paywallRules: [rule])

        // Assert that the result is true, meaning the rule is bypassed for registered users
        XCTAssertFalse(result, "Registered user should bypass the rule.")

        // Restore original access token value
        Subscriptions.Identity.accessToken = originalAccessToken
    }

    func testV1SKUMatchesAndTrueNilEnt() {
        // e: [true, 'SKU1'] ent: [false] means the rule will be bypassed by a user with “SKU1”
        // Setup user entitlements with a specific SKU
        let userEntitlements = EntitlementsResponse(skus: [EntitlementResponseSKU(sku: "UnitTestSKU1")],
                                                    zones: nil,
                                                    edgescape: nil)

        let ruleBudget = RuleBudget(budgetType: .calendar,
                                    calendarType: nil,
                                    calendarWeekday: nil,
                                    rollingType: nil,
                                    rollingDays: nil)

        // Setup paywall rules with a matching SKU entitlement
        let rule = PaywallRule(id: 1,
                               conditions: [:],
                               budget: ruleBudget,
                               entitlementsSKUs: [.bool(true), .string("UnitTestSKU1")],
                               entitlementsZones: nil,
                               campaignLink: nil,
                               maxPageViews: 1,
                               campaignCode: nil)

        // Check for entitlement match
        let result = PaywallEvaluator.evaluateEntitlements(userEntitlements: userEntitlements, paywallRules: [rule])

        // Assert that the result is true, indicating a direct SKU match
        XCTAssertFalse(result, "User with matching SKU should bypass the rule.")
    }

    func testV2ZonesMatchNilE() {
        // e: [false] ent: [true, 123] means the rule will be bypassed by a user with the entitlement 123

        // Setup user entitlements with specific zones
        let userEntitlements = EntitlementsResponse(skus: nil, zones: [123, 234, 345], edgescape: nil)

        let ruleBudget = RuleBudget(budgetType: .calendar,
                                    calendarType: nil,
                                    calendarWeekday: nil,
                                    rollingType: nil,
                                    rollingDays: nil)

        // Setup paywall rules with a matching zone entitlement
        let rule = PaywallRule(id: 3,
                               conditions: [:],
                               budget: ruleBudget,
                               entitlementsSKUs: nil,
                               entitlementsZones: [.bool(true), .int(123)],
                               campaignLink: nil,
                               maxPageViews: 100,
                               campaignCode: nil)

        // Check for entitlement match
        let result = PaywallEvaluator.evaluateEntitlements(userEntitlements: userEntitlements, paywallRules: [rule])

        // Assert that the result is true, indicating a direct zone match
        XCTAssertFalse(result, "User with matching zone should bypass the rule.")
    }

    // TODO: AM-6150 - How should false values be handled?
    // We've been given clear instruction on how to handle true and matching strings.
    // How should we handle false and matching strings?
    
    private func mockPayWallRules(budget1: Int, budget2: Int) -> [PaywallRule] {
        return [
            PaywallRule(
                id: 1,
                conditions: [
                    "location": RuleCondition(isIn: true, values: ["US", "CA"]),
                    "subscription": RuleCondition(isIn: false, values: ["premium"])
                ],
                budget: RuleBudget(
                    budgetType: .calendar,
                    calendarType: .monthly,
                    calendarWeekday: nil,
                    rollingType: nil,
                    rollingDays: nil
                ),
                entitlementsSKUs: [.string("accessToExclusiveContent"), .bool(true)],
                entitlementsZones: nil,
                campaignLink: "https://example.com/campaign1",
                maxPageViews: budget1,
                campaignCode: "SPRING_SALE"
            ),
            PaywallRule(
                id: 2,
                conditions: [
                    "device": RuleCondition(isIn: true, values: ["iOS", "Android"]),
                    "member": RuleCondition(isIn: true, values: ["true"])
                ],
                budget: RuleBudget(
                    budgetType: .rolling,
                    calendarType: nil,
                    calendarWeekday: nil,
                    rollingType: .days,
                    rollingDays: 30
                ),
                entitlementsSKUs: nil,
                entitlementsZones: nil,
                campaignLink: "https://example.com/campaign2",
                maxPageViews: budget2,
                campaignCode: "SUMMER_FUN"
            )
        ]
    }
}
