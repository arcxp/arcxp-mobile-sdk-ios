//
//  ConditionsViewController.swift
//  Example
//
//  Created by David Seitz Jr on 4/21/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import UIKit
import ArcXP

protocol ConditionsViewControllerDelegate: AnyObject {
    func didFinishUpdating(_ conditions: [String: String]?)
}

class ConditionsViewController: UIViewController {

    var conditions: [String: String]? {
        didSet {
            // Update ordered conditions to match new values.
            guard let conditions = conditions else { orderedConditions = nil; return }
            var newOrderedConditions = [(key: String, value: String)]()
            for condition in conditions {
                newOrderedConditions.append((condition.key, condition.value))
            }
            // Update and sort alphabetically by key.
            orderedConditions = newOrderedConditions.sorted(by: { $0.key < $1.key })
        }
    }

    /// An ordered version of the unordered `conditions` dictionary, intended for easy display in a table view.
    var orderedConditions: [(key: String, value: String)]? {
        didSet {
            tableView?.reloadData()
        }
    }

    weak var delegate: ConditionsViewControllerDelegate?

    @IBOutlet private weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Conditions"
        let addConditionButton = UIBarButtonItem(barButtonSystemItem: .add,
                                                 target: self,
                                                 action: #selector(didTapAddConditionButton))
        navigationItem.rightBarButtonItem = addConditionButton

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done,
                                         target: self,
                                         action: #selector(didTapDoneButton))
        navigationItem.leftBarButtonItem = doneButton

        tableView.delegate = self
        tableView.dataSource = self
    }

    // MARK: - Button Interaction

    @objc private func didTapAddConditionButton() {
        showAddConditionPrompt()
    }

    @objc private func didTapDoneButton() {
        delegate?.didFinishUpdating(conditions)
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Convenience Methods

    private func showAddConditionPrompt() {

        let addConditionPrompt = UIAlertController()

        let deviceClassAction = UIAlertAction(title: "Add Device Class", style: .default) { _ in
            self.showAddDeviceClassPrompt()
        }

        let contentTypeAction = UIAlertAction(title: "Add Content Type", style: .default) { _ in
            self.showAddContentTypePrompt()
        }

        let customConditionAction = UIAlertAction(title: "Add Custom Condition", style: .default) { _ in
            self.showAddCustomConditionPrompt()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        for action in [deviceClassAction, contentTypeAction, customConditionAction, cancelAction] {
            addConditionPrompt.addAction(action)
        }

        present(addConditionPrompt, animated: true)
    }

    private func showAddDeviceClassPrompt() {

        let addDeviceClassPrompt = UIAlertController(title: "Add Device Class",
                                                     message: "Type a value for your device class",
                                                     preferredStyle: .alert)

        addDeviceClassPrompt.addTextField { $0.placeholder = "Device class value" }

        let okAction = UIAlertAction(title: "OK", style: .default) { _ in

            guard let deviceClassTextField = addDeviceClassPrompt.textFields?.first,
                  let conditionValue = deviceClassTextField.text else {
                      print("No condition was added for device class.")
                      return
                  }

            if self.conditions == nil { self.conditions = [String: String]() }
            self.conditions?["deviceClass"] = conditionValue
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        for action in [okAction, cancelAction] { addDeviceClassPrompt.addAction(action) }

        present(addDeviceClassPrompt, animated: true)
    }

    private func showAddContentTypePrompt() {

        let addContentTypePrompt = UIAlertController(title: "Add Content Type",
                                                     message: "Type a value for your content type",
                                                     preferredStyle: .alert)

        addContentTypePrompt.addTextField { $0.placeholder = "Content type value" }

        let okAction = UIAlertAction(title: "OK", style: .default) { _ in

            guard let contentTypeTextField = addContentTypePrompt.textFields?.first,
                  let conditionValue = contentTypeTextField.text else {
                      print("No condition was added for content type.")
                      return
                  }

            if self.conditions == nil { self.conditions = [String: String]() }
            self.conditions?["contentType"] = conditionValue
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        for action in [okAction, cancelAction] { addContentTypePrompt.addAction(action) }

        present(addContentTypePrompt, animated: true)
    }

    private func showAddCustomConditionPrompt() {

        let addCustomConditionPrompt = UIAlertController(title: "Add Device Class",
                                                     message: "Type a value for your device class",
                                                     preferredStyle: .alert)

        addCustomConditionPrompt.addTextField { $0.placeholder = "Custom client condition key" }
        addCustomConditionPrompt.addTextField { $0.placeholder = "Custom client condition value" }

        let okAction = UIAlertAction(title: "OK", style: .default) { _ in

            guard let conditionKeyTextField = addCustomConditionPrompt.textFields?[0],
                  let conditionValueTextField = addCustomConditionPrompt.textFields?[1],
                  let key = conditionKeyTextField.text,
                  let value = conditionValueTextField.text else {
                      return
                  }
            if self.conditions == nil { self.conditions = [String: String]() }
            self.conditions?[key] = value
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        for action in [okAction, cancelAction] { addCustomConditionPrompt.addAction(action) }

        present(addCustomConditionPrompt, animated: true)
    }
}

// MARK: - UITableView

extension ConditionsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let conditions = conditions else { return 1 }
        return conditions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let condition = orderedConditions?[indexPath.row] else {
            let addConditionCell = UITableViewCell()
            addConditionCell.textLabel?.text = "Add new client condition..."
            return addConditionCell
        }
        let conditionCell = UITableViewCell()
        conditionCell.textLabel?.text = "\(condition.key): \(condition.value)"
        return conditionCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if conditions == nil || conditions?.count == 0 { showAddConditionPrompt() }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard let condition = orderedConditions?[indexPath.row] else {
            print("Failed to delete condition at: \(indexPath)")
            return
        }

        conditions?[condition.key] = nil
    }
}
