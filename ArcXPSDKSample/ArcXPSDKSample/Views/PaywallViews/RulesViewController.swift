//
//  RulesViewController.swift
//  Example
//
//  Created by David Seitz Jr on 8/16/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import UIKit
import ArcXP

class RulesViewController: UITableViewController {

    private let evaluationResultTableViewCellID = String(describing: EvaluationResultTableViewCell.self)
    private let ruleTableViewCellID = String(describing: RuleTableViewCell.self)

    let paywallRules = PaywallManager.activePaywallRules
    let userRules = PaywallCacheManager.userRules
    var rulesPassed = true

    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCells()
        title = "Evaluation Results"
    }

    private func registerTableViewCells() {
        let evalutionResultCell = UINib(nibName: evaluationResultTableViewCellID, bundle: Bundle.main)
        let ruleTableViewCell = UINib(nibName: ruleTableViewCellID, bundle: Bundle.main)
        tableView.register(evalutionResultCell, forCellReuseIdentifier: evaluationResultTableViewCellID)
        tableView.register(ruleTableViewCell, forCellReuseIdentifier: ruleTableViewCellID)
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {

        case 0:
            // Rule evaluation status
            return 1

        case 1:
            // List of rules
            return paywallRules?.count ?? 0

        default:
            // Out of expected range
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.section {
        case 0:
            // Rule evaluation status
            guard let evaluationResultCell =
                    tableView.dequeueReusableCell(withIdentifier: evaluationResultTableViewCellID) as? EvaluationResultTableViewCell else {
                print("Error: There was a problem loading the evaluation result table view cell.")
                let errorCell = UITableViewCell()
                errorCell.textLabel?.text = "Error: Couldn't load evaluation result cell."
                return errorCell
            }
            evaluationResultCell.rulesPassed = rulesPassed

            return evaluationResultCell

        case 1:
            // Rules list
            guard let ruleTableViewCell = tableView.dequeueReusableCell(withIdentifier: ruleTableViewCellID) as? RuleTableViewCell,
                  let paywallRule = paywallRules?[indexPath.row] else {
                print("Error: There was a problem loading the rule table view cell.")
                let errorCell = UITableViewCell()
                errorCell.textLabel?.text = "Error: Couldn't load rule cell."
                return errorCell
            }
            let userRule = userRules.rules[paywallRule.id]
            ruleTableViewCell.setUp(paywallRule: paywallRule, userRule: userRule)
            if !rulesPassed,
               let userRule = userRule,
               userRule.counter >= paywallRule.maxPageViews {
                ruleTableViewCell.updateForTrippedRule()
            }
            return ruleTableViewCell

        default:
            break
        }
        return UITableViewCell()
    }
}
