//
//  ArcXPSDKSampleApp.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 5/15/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import SwiftUI

@main
struct ExampleUnifiedSDKApp: App {
    init() {
        SDKInitializer.configureArcXPServices()
        print("Unified SDK initialized")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
