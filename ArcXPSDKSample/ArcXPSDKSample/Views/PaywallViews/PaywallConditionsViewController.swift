//
//  PaywallConditionsViewController.swift
//  Example
//
//  Created by Davis, Tyler on 7/21/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import ArcXP
import UIKit

let conditionTableViewCellID = "ConditionTableViewCell"

/// This is a convenient way to pass in expected device class and content type values intended for mock page view data.
protocol PageViewConditionsDelegate: AnyObject {
    var contentType: String? { get set }
}

/// A view controller which provides a few basic options for selecting a device class and content type.
class PageViewConditionsViewController: UITableViewController {

    /// String values to be compared against content type values provided by the backend..
    var contentTypes: [String] = ["gallery", "story", "video"]

    weak var pageViewConditionsDelegate: PageViewConditionsDelegate?

    // MARK: - View Setup

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Page View Conditions"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: conditionTableViewCellID)
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentTypes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: conditionTableViewCellID)!

        // Grab the specific type to be used in this row.
        let type = contentTypes[indexPath.row]

        // If selected conditions contains the specified type, add a checkmark. Otherwise, remove the checkmark.
        if let delegate = pageViewConditionsDelegate, delegate.contentType == type {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        // Add the appropriate text for the given row and section.
        cell.textLabel?.text = type
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        switch indexPath.section {
        case 0:
            // Content type selected
            let selectedContentType = contentTypes[indexPath.row]
            // If the content type isn't already selected, set it as selected. If it is, set it as nil.
            pageViewConditionsDelegate?.contentType = pageViewConditionsDelegate?.contentType != selectedContentType ? selectedContentType : nil
        default:
            // Out of range
            return
        }

        // Update the tableview to add the approriate cell accessoryType UI.
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Content Type"
    }
}
