//
//  PaywallViewController.swift
//  Example
//
//  Created by Seitz, David on 6/30/2022.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import ArcXP
import UIKit

// MARK: - Unique Table View Cells

class PaywallDatePickerCell: UITableViewCell {
    @IBOutlet weak var primaryLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker?
}

class PaywallSwitchCell: UITableViewCell {
    @IBOutlet weak var primaryLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    weak var delegate: PaywallSwitchCellDelegate?
    @IBAction func didToggleSwitch(_ sender: UISwitch) {
        delegate?.didToggleSwitch(toggle: sender)
    }
}

protocol PaywallSwitchCellDelegate: AnyObject {
    func didToggleSwitch(toggle: UISwitch)
}

// MARK: - Paywall Table View Row

/// Provides the appropriate table view row cell and action based on the provided index path.
fileprivate enum PaywallTableViewRow {

    // Section 0: Backend parameters
    case userEntitlements
    case activePaywallRules

    // Section 1: Input parameters
    case pageID(pageID: String?)
    case conditions(conditionsCount: Int?)
    case countView

    // Section 2: Test parameters
    case evaluationDate

    // Section 3: Cache management
    case viewCache
    case clearCache

    // Convenience methods

    // swiftlint:disable cyclomatic_complexity
    /// Provides the appropriate Paywall row value based on the provided index path.
    /// - parameter indexPath: The index path for which a row should be provided.
    /// - parameter additionalData: An optional value for specific cases where cell labels may be informed by data.
    /// - returns: The row data associated with the provided `indexPath`, including cell and action data.
    static func row(for indexPath: IndexPath, additionalData: Any? = nil) -> PaywallTableViewRow? {
        switch indexPath.section {

        case 0:
            switch indexPath.row {
            case 0:  return .userEntitlements
            case 1:  return .activePaywallRules
            default: return nil
            }

        case 1:
            switch indexPath.row {
            case 0:  return .pageID(pageID: additionalData as? String)
            case 1:  return .conditions(conditionsCount: additionalData as? Int)
            case 2:  return .countView
            default: return nil
            }

        case 2:
            switch indexPath.row {
            case 0:  return .evaluationDate
            default: return nil
            }

        case 3:
            switch indexPath.row {
            case 0:  return .viewCache
            case 1:  return .clearCache
            default: return nil
            }

        default: return nil
        }
    }
    // swiftlint:enable cyclomatic_complexity

    /// Provides the appropriate cell view for the current value.
    /// - parameter tableView: The tableView where reuseable cells will be dequeued from.
    /// - returns: The cell for the current value.
    func cell(for tableView: UITableView, sender: PaywallViewController) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: PaywallViewController.reuseableGenericCellID)!
        cell.prepareForReuse()
        cell.textLabel?.textColor = .label
        cell.accessoryType = .disclosureIndicator

        switch self {
        case .userEntitlements:
            cell.textLabel?.text = "User Entitlements"

        case .activePaywallRules:
            cell.textLabel?.text = "Active Paywall Rules"

        case .pageID(let pageID):
            if let pageID = pageID {
                cell.textLabel?.text = "Page ID: \(pageID)"
            } else {
                cell.textLabel?.text = "Set Page ID"
            }
            cell.accessoryType = .none

        case .conditions(let conditionsCount):
            cell.textLabel?.text = "Conditions: \(conditionsCount ?? 0)"

        case .evaluationDate:
            cell = tableView.dequeueReusableCell(withIdentifier: "PaywallDateCell")!
            sender.datePicker = (cell as? PaywallDatePickerCell)?.datePicker
            (cell as? PaywallDatePickerCell)?.primaryLabel.text = "Evaluation Date"

        case .countView:
            cell = tableView.dequeueReusableCell(withIdentifier: "PaywallCountViewCell")!
            (cell as? PaywallSwitchCell)?.primaryLabel.text = "Count View"
            (cell as? PaywallSwitchCell)?.detailLabel.text = "Determines whether or not the \"evaluation\" action will count a view towards cached rule budgets."
            (cell as? PaywallSwitchCell)?.detailLabel.textColor = .secondaryLabel
            (cell as? PaywallSwitchCell)?.delegate = sender

        case .viewCache:
            cell.textLabel?.text = "View Cache"

        case .clearCache:
            cell.textLabel?.text = "Clear Cache"
            cell.accessoryType = .none
            cell.textLabel?.textColor = .systemRed
        }

        return cell
    }

    func performAction(for sender: PaywallViewController) {

        switch self {
        case .userEntitlements:
            sender.showSubscriptions = true
            sender.performSegue(withIdentifier: "showPaywallContent", sender: nil)

        case .activePaywallRules:
            sender.showSubscriptions = false
            sender.performSegue(withIdentifier: "showPaywallContent", sender: nil)

        case .pageID:
            sender.updatePageID()

        case .conditions:
            sender.performSegue(withIdentifier: "showConditionsViewController", sender: nil)

        case .evaluationDate:
            // Cell view contains internal logic for date selection.
            break

        case .countView:
            // Switch updates handled through delegation with PaywallSwitchCellDelegate.
            break

        case .viewCache:
            sender.performSegue(withIdentifier: "showCache", sender: nil)

        case .clearCache:
            sender.promptClearCache()
        }
    }
}

// MARK: - PaywallStatusViewController

class PaywallViewController: UITableViewController, PageViewConditionsDelegate {

    fileprivate static let reuseableGenericCellID = "PaywallReuseableGenericCellID"

    var countView = false
    var showSubscriptions = false
    var pageID: String?

    // Conditions
    var contentType: String?
    var conditions: [String: String]?

    @IBOutlet weak var datePicker: UIDatePicker!
    var countViewSwitch: UISwitch?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: PaywallViewController.reuseableGenericCellID)

        let evaluationButton = UIBarButtonItem(title: "Evaluate",
                                               style: .plain,
                                               target: self,
                                               action: #selector(self.evaluate))

        navigationItem.rightBarButtonItem = evaluationButton
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let paywallContentVC = segue.destination as? PaywallContentViewController {
            if showSubscriptions {
                paywallContentVC.entitlements = PaywallManager.entitlementResponse
            } else {
                paywallContentVC.activeRules = PaywallManager.activePaywallRules
            }
        } else if let paywallConditionsVC = segue.destination as? PageViewConditionsViewController {
            paywallConditionsVC.pageViewConditionsDelegate = self
        } else if let conditionsViewController = segue.destination as? ConditionsViewController {
            conditionsViewController.delegate = self
            conditionsViewController.conditions = conditions
        }
    }

    // MARK: - Convenience Methods

    fileprivate func updatePageID() {
        let editStringAlert = UIAlertController(title: "Page ID",
                                                message: "Enter a new value for the page ID",
                                                preferredStyle: .alert)
        var editStringTextField: UITextField?
        editStringAlert.addTextField { $0.placeholder = "Enter ID"; editStringTextField = $0 }

        let doneAction = UIAlertAction(title: "Done", style: .default) { [weak self, editStringTextField] _ in
            guard let newValue = editStringTextField?.text,
                    newValue != "" else { print("No text was entered."); return }
            self?.pageID = newValue
            self?.tableView.reloadData()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        for action in [doneAction, cancelAction] { editStringAlert.addAction(action) }

        present(editStringAlert, animated: true)
    }

    fileprivate func promptClearCache() {

        let clearCacheAlert = UIAlertController(title: "Clear Cache",
                                                message: "Are you sure you want to permanently delete your Paywall cache?",
                                                preferredStyle: .alert)

        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            PaywallCacheManager.clearPaywallCache()
            self.pageID = nil
            self.tableView.reloadData()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        for action in [yesAction, cancelAction] { clearCacheAlert.addAction(action) }

        present(clearCacheAlert, animated: true)
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:  return 3
        case 2:  return 1
        default: return 2
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:  return "Backend parameters"
        case 1:  return "Input parameters"
        case 2:  return "Test parameters"
        case 3:  return "Cache management"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var additionalData: Any?
        if indexPath.section == 1 && indexPath.row == 0 {
            additionalData = pageID
        } else if indexPath.section == 1 && indexPath.row == 1 {
            additionalData = conditions?.count
        }

        guard let row = PaywallTableViewRow.row(for: indexPath, additionalData: additionalData) else {
            let cell = UITableViewCell()
            cell.textLabel?.text = "Error loading cell"
            return cell
        }

        return row.cell(for: tableView, sender: self)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PaywallTableViewRow.row(for: indexPath)?.performAction(for: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Evaluation
// Evaluation has been isolated below to show clearly how to perform an evaluation, separated from UI logic.

extension PaywallViewController {

    @objc func evaluate() {
        guard let pageID = pageID else {
            print("Error: Evaluation failed due to missing page ID.")
            presentAlert(title: "Error", message: "Please enter a page ID before attempting to evaluate.")
            return
        }

        let date = datePicker?.date ?? Date()

        // Evaluate the provided conditions against Paywall rules to determine whether or not content should be shown.
        let evaluationResult = PaywallManager.evaluate(contentID: pageID,
                                                       conditions: conditions,
                                                       countTowardsBudget: countView,
                                                       readDate: date)
        switch evaluationResult {
        case .success:
            print("Successfully evaluated all rules.")
        case .failure(let error):
            print("There was an error while evaluating paywall rules.")
            switch error {
            case .rulesTripped(let rules):
                print("One or more rules have tripped. Tripped rules: \(String(describing: rules))")
            case .noActivePaywallRules:
                print("No active paywall rules were available to evaluate against.")
            }
        }
        let testRulesViewController = RulesViewController()
        switch evaluationResult {
        case .success:
            testRulesViewController.rulesPassed = true
        case .failure:
            testRulesViewController.rulesPassed = false
        }

        show(testRulesViewController, sender: self)
    }
}

// MARK: - Client Conditions View Controller Delegate

extension PaywallViewController: ConditionsViewControllerDelegate {
    func didFinishUpdating(_ conditions: [String: String]?) {
        self.conditions = conditions
        tableView.reloadData()
    }
}

// MARK: - Paywall Switch Cell Delegate

extension PaywallViewController: PaywallSwitchCellDelegate {
    func didToggleSwitch(toggle: UISwitch) {
        countView = toggle.isOn
    }
}
