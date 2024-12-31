//
//  UIViewController+Alert.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 7/30/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {

    /// Presents an alert on view controller
    /// - Parameters:
    ///   - title: Alert title
    ///   - message: Message for alert
    ///   - affirmativeActonTitle: Affirmative action button title
    ///   - showCancelAction: Bool flag to show/hide Cancel button
    ///   - affirmativeHandler: completion handler for the affirmative action button tap
    public func presentAlert(title: String?,
                             message: String?,
                             affirmativeActonTitle: String? = "OK",
                             showCancelAction: Bool = false,
                             affirmativeHandler: ((UIAlertAction) -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: affirmativeActonTitle, style: .default, handler: affirmativeHandler)
            alert.addAction(okAction)
            if showCancelAction {
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alert.addAction(cancelAction)
            }
            self?.present(alert, animated: true, completion: nil)
        }
    }
}
