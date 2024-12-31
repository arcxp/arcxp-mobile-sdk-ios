//
//  ContentView.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 5/15/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                ArcVideoView()
                    .navigationBarTitle("Arc XP SDK Video Sample", displayMode: .inline)
            }
            .tabItem {
                Label("Video", systemImage: "video.fill")
            }
            ArcCommerceView()
                .tabItem {
                    Label("Commerce", systemImage: "bag")
                }
            ArcContentView()
                .tabItem {
                    Label("Content", systemImage: "newspaper.fill")
                }
        }
    }
}

@available(iOS 17, *)
#Preview {
    ContentView()
}
