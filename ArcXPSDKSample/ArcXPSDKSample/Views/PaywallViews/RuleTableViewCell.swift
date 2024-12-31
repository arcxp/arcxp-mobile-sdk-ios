//
//  RuleTableViewCell.swift
//  Example
//
//  Created by David Seitz Jr on 8/16/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import UIKit
import ArcXP

class RuleTableViewCell: UITableViewCell {

    @IBOutlet weak var campaignCodeLabel: UILabel!
    @IBOutlet weak var cacheStatusLabel: UILabel!
    @IBOutlet weak var ruleIdLabel: UILabel!
    @IBOutlet weak var budgetLabel: UILabel!
    @IBOutlet weak var lastResetDateLabel: UILabel!
    @IBOutlet weak var totalViewedPagesLabel: UILabel!
    @IBOutlet weak var conditionsLabel: UILabel!
    @IBOutlet weak var entitlementsLabel: UILabel!

    // swiftlint:disable function_body_length
    func setUp(paywallRule: PaywallRule, userRule: UserRules.UserRule?) {
        campaignCodeLabel.text = paywallRule.campaignCode ?? "\(paywallRule.id)"
        ruleIdLabel.text = "Rule ID: \(paywallRule.id)"
        totalViewedPagesLabel.text = "Total viewed pages: \(userRule?.viewedPages.count ?? 0)"

        if let budgetFilled = userRule?.counter {
            budgetLabel.text = "Budget: \(budgetFilled)/\(paywallRule.maxPageViews)"
        } else {
            budgetLabel.text = "Budget: \(paywallRule.maxPageViews)"
        }

        if userRule != nil {
            cacheStatusLabel.text = "Cached"
            cacheStatusLabel.textColor = .init(red: 103/255,
                                               green: 188/255,
                                               blue: 48/255,
                                               alpha: 1)
        } else {
            cacheStatusLabel.text = "Not cached"
        }

        if let date = userRule?.lastResetDate {
            lastResetDateLabel.text = "Last reset date: \(date)"
        } else {
            lastResetDateLabel.text = "Last reset date: N/A"
        }

        var conditionsText = "Conditions:"
        var inConditions = Set<String>()
        var outConditions = Set<String>()
        paywallRule.conditions.forEach { _, ruleCondition in
            if ruleCondition.isIn {
                ruleCondition.values.forEach { value in
                    inConditions.insert(value)
                }
            } else {
                ruleCondition.values.forEach { value in
                    outConditions.insert(value)
                }
            }
        }
        if inConditions.count > 0 {
            conditionsText.append("\n- In: ")
            inConditions.forEach { inConditionName in
                conditionsText.append("\(inConditionName) ")
            }
        }
        if outConditions.count > 0 {
            conditionsText.append("\n- Out: ")
            outConditions.forEach { outConditionName in
                conditionsText.append("\(outConditionName) ")
            }
        }
        conditionsLabel.text = conditionsText

        var entitlementsText = "Entitlements: "
        if let entitlements = paywallRule.entitlementsSKUs {
            entitlements.forEach { entitlement in
                switch entitlement {
                case .bool(let bool):
                    entitlementsText.append("\(bool) ")
                case .string(let string):
                    entitlementsText.append("\(string) ")
                case .int(let number):
                    entitlementsText.append("\(number)")
                }
            }
            entitlementsLabel.text = entitlementsText
        }
    }
    // swiftlint:enable function_body_length

    func updateForTrippedRule() {
        backgroundColor = .init(red: 255/255,
                                green: 220/255,
                                blue: 220/255,
                                alpha: 1)
        budgetLabel.textColor = .red
    }
}
