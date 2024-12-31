//
//  MockLoggingManagerObserver.swift
//  ArcXPContentTests
//
//  Created by David Seitz Jr on 2/2/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation
import ArcXP

struct MockLoggingManagerObserver: LoggingManagerObserver {
    func loggingManagerDidReportLog(message: String, level: LoggingManager.Level, metadata: [LoggingManager.Metadata]?) {
        print("MockLoggingManagerObserver observed new log at level: \(level).")
    }
}
