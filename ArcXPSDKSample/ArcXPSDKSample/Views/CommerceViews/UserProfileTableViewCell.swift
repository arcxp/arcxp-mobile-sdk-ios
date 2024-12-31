//
//  UserProfileTableViewCell.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 7/31/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import UIKit

class UserProfileTableViewCell: UITableViewCell {

    @IBOutlet private weak var valueLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    /// Sets the ``descriptionLabel`` and ``valueLabel``  to the provided description and value strings.
    /// - Parameters:
    ///     - description: The description string to set the ``descriptionLabel`` text to.
    ///     - value: The value string to set the ``valueLabel`` text to.
    func set(description: String, value: String) {
        descriptionLabel.text = description
        valueLabel.text = value
    }
}
