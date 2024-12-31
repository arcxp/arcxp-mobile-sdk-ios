//
//  PageViewData.swift
//  ArcXPCommerce
//
//  Created by David Seitz Jr on 7/13/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

public struct PageViewData: Codable {
    public var pageId: String
    public var conditions: [String: String]

    public init(pageId: String, conditions: [String: String]) {
        self.pageId = pageId
        self.conditions = conditions
    }
}

/// A  model representing a collection of rules the user has interacted with.
public struct UserRules: Codable {
    public typealias RuleID = Int
    public var rules: [RuleID: UserRule]

    /// This keeps track of the user's interaction with a rule, including how many times a user can view content for a rule, and when that rule's counter should be reset.
    public class UserRule: Codable, Equatable {

        /// The maximum allowed views for this rule.
        public let budget: Int

        /// The number of views recorded for the current budget cycle.
        public var counter = 0

        /// The last time the budget counter was reset.
        public var lastResetDate: Date

        /// All pages that have been viewed related to this rule. When viewed once in a budget cycle, viewed pages should persist and not count against future budgets.
        public var viewedPages = [String]()

        /// Reports whether or not the budget limit has been met..
        public var budgetLimitMet: Bool {
            return counter >= budget
        }

        init(budget: Int, lastResetDate: Date) {
            self.budget = budget
            self.lastResetDate = lastResetDate
        }

        public static func == (lhs: UserRules.UserRule, rhs: UserRules.UserRule) -> Bool {
            return lhs.budget == rhs.budget &&
            lhs.counter == rhs.counter &&
            lhs.lastResetDate == rhs.lastResetDate &&
            lhs.viewedPages == rhs.viewedPages
        }
    }
}
