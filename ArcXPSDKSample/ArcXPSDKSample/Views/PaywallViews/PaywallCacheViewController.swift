//
//  PaywallCacheViewController.swift
//  Example
//
//  Created by Davis, Tyler on 8/16/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import ArcXP
import UIKit

let cacheTableViewCellID = "CacheTableViewCell"

class PaywallCacheViewController: UITableViewController {

    var userRulesData: UserRules?

    override func viewDidLoad() {
        super.viewDidLoad()

        userRulesData = PaywallCacheManager.userRules
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cacheTableViewCellID)
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return userRulesData?.rules.count ?? 0
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        guard let rules = userRulesData?.rules else { return 0 }

        let ruleId = Array(rules.keys)[section]
        return rules[ruleId]?.viewedPages.count ?? 0
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cacheTableViewCellID)!

        let rules = userRulesData?.rules
        let ruleId = Array(rules!.keys)[indexPath.section]
        let viewedPages = rules?[ruleId]?.viewedPages

        let pageId = viewedPages?[indexPath.row] ?? ""
        cell.textLabel?.text = "Page ID: \(pageId)"

        return cell
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        guard let rules = userRulesData?.rules else { return nil }

        let ruleId = Array(rules.keys)[section]
        return "Rule ID: " + String(ruleId)
    }

}
