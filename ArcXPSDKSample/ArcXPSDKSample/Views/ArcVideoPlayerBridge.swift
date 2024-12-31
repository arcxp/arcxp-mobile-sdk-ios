//
//  ArcVideoPlayerBridge.swift
//  ArcXPSDKSample
//
//  Created by Mahesh Venkateswarlu on 7/23/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import Foundation
import SwiftUI

struct ArcVideoPlayerBridge: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        // swiftlint:disable line_length
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "Video") as? ConfigureVideoViewController else {
            fatalError("Unable to instantiate view controller with identifier 'Video'")
        }
        // swiftlint:enable line_length
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
