//
//  PaywallContentViewController.swift
//  Example
//
//  Created by Davis, Tyler on 7/19/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import ArcXP
import UIKit

class PaywallContentViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!

    var activeRules: [PaywallRule]?
    var entitlements: EntitlementsResponse?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        if let activeRules = activeRules, let JSON = try? encoder.encode(activeRules) {
            textView?.text = String(data: JSON, encoding: .utf8)
        } else if let JSON = try? encoder.encode(entitlements) {
            textView?.text = String(data: JSON, encoding: .utf8)
        }
    }
}
