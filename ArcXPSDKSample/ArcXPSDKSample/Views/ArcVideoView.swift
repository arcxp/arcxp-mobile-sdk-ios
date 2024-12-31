//
//  ArcVideoView.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 5/15/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import SwiftUI

struct ArcVideoView: View {
    var body: some View {
        ArcVideoPlayerBridge()
    }
}

@available(iOS 17, *)
#Preview {
    ArcVideoView()
}
