//
//  CommerceBridge.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 7/29/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import Foundation
import SwiftUI

struct CommerceBridge: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let storyboard = UIStoryboard(name: "Commerce", bundle: nil)
        // swiftlint:disable line_length
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "UserAccountNavigationController") as? UINavigationController else {
            fatalError("Unable to instantiate view controller with identifier 'UserProfileViewController'")
        }
        // swiftlint:enable line_length
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}
