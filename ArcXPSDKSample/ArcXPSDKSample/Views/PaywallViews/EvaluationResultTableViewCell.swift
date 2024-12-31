//
//  EvaluationResultTableViewCell.swift
//  Example
//
//  Created by David Seitz Jr on 8/17/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import UIKit

class EvaluationResultTableViewCell: UITableViewCell {

    @IBOutlet private weak var resultLabel: UILabel!

    var rulesPassed = true {
        didSet {
            if rulesPassed {
                resultLabel.text = "Rules Passed"
                contentView.backgroundColor = .init(red: 103/255,
                                                    green: 188/255,
                                                    blue: 48/255,
                                                    alpha: 1)
            } else {
                resultLabel.text = "Rule Tripped"
                contentView.backgroundColor = .red
            }
        }
    }
}
