//
//  ActiveRule.swift
//  ArcXPCommerce
//
//  Created by David Seitz Jr on 7/12/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

// MARK: - PaywallRule
/// Represents a rule from the Paywall, incorporating conditions and budget for evaluating content access.
public struct PaywallRule: Codable {
    public let id: Int
    public let conditions: [String: RuleCondition]
    public let budget: RuleBudget
    public let entitlementsSKUs: [PaywallEntitlmentValue]?
    public let entitlementsZones: [PaywallEntitlmentValue]?
    public let campaignLink: String?
    public let maxPageViews: Int
    public let campaignCode: String?

    enum CodingKeys: String, CodingKey {
        case entitlementsSKUs = "e"
        case entitlementsZones = "ent"
        case campaignLink = "cl"
        case maxPageViews = "rt"
        case campaignCode = "cc"
        case id, conditions, budget
    }
}

// MARK: - Budget
/// Encapsulates budgeting logic for paywall rules, including various budgeting strategies.
public struct RuleBudget: Codable {
    public let budgetType: BudgetType
    public let calendarType: CalendarType?
    public let calendarWeekday: WeekdayType?
    public let rollingType: RollingType?
    public let rollingDays: Int?

    public enum BudgetType: String, Codable { case calendar = "Calendar", rolling = "Rolling" }
    public enum RollingType: String, Codable { case days = "Days", hours = "Hours" }
    public enum CalendarType: String, Codable { case weekly = "Weekly", monthly = "Monthly" }

    public enum WeekdayType: String, Codable {
        case sunday, monday, tuesday, wednesday, thursday, friday, saturday

        public func toDateComponentDay() -> Int {
            switch self {
            case .sunday:
                return 1
            case .monday:
                return 2
            case .tuesday:
                return 3
            case .wednesday:
                return 4
            case .thursday:
                return 5
            case .friday:
                return 6
            case .saturday:
                return 7
            }
        }

        private static func weekday(from int: Int) -> WeekdayType? {
            switch int {
            case 1:
                return .sunday
            case 2:
                return .monday
            case 3:
                return .tuesday
            case 4:
                return .wednesday
            case 5:
                return .thursday
            case 6:
                return .friday
            case 7:
                return .saturday
            default:
                return nil
            }
        }

        private static func weekday(from date: Date) -> WeekdayType? {
            let weekdayInt = Calendar.current.component(.weekday, from: date)
            return weekday(from: weekdayInt)
        }

        /// Reports the date for the weekday following the initial date provided.
        /// - parameter weekday: The weekday in which a date is needed for.
        /// - parameter initialDate: The date preceeding the weekday for which a date is needed for.
        /// - returns: The specific date of the weekday requested, after the initial date provided.
        static func date(for weekday: RuleBudget.WeekdayType?, immediatelyFollowing initialDate: Date) -> Date? {
            guard let initialDateWeekday = RuleBudget.WeekdayType.weekday(from: initialDate),
                  let weekday = weekday else {
                devPrint("PaywallManager failed to get the date for following weekday due to invalid parameters.")
                return nil
            }

            var remainingDaysTillWeekday = weekday.toDateComponentDay() - initialDateWeekday.toDateComponentDay()
            let dayFallsInCurrentWeek = weekday.toDateComponentDay() > initialDateWeekday.toDateComponentDay()

            if !dayFallsInCurrentWeek {
                // Number is negative. Add a week of days to get the correct remaining days.
                remainingDaysTillWeekday += 7
            }

            return Calendar.current.date(byAdding: .day, value: remainingDaysTillWeekday, to: initialDate)?.startOfDay
        }
    }
}

// MARK: - RuleCondition
/// Represents a single condition within a paywall rule, indicating inclusion and specific values.
public struct RuleCondition: Codable {
    public let isIn: Bool
    public let values: [String]

    enum CodingKeys: String, CodingKey {
        case isIn = "in"
        case values
    }
}

extension RuleCondition {
    /// Reports whether the condition is met by the provided value.
    /// - parameter value: The value to evaluate against the condition.
    /// - returns: A boolean indicating whether the value meets the condition.
    func isMet(by value: String) -> Bool {
        return isIn == values.contains(value)
    }
}

// MARK: - EntitlementValue
/// Handles mixed type values (Bool, String, Int) for entitlements, streamlining SKU and zone handling.
public enum PaywallEntitlmentValue: Codable, Equatable {
    case bool(Bool), string(String), int(Int)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else {
            let error = DecodingError.Context(codingPath: decoder.codingPath,
                                              debugDescription: "Expected a bool, string, or int")
            throw DecodingError.typeMismatch(PaywallEntitlmentValue.self, error)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        }
    }
}
