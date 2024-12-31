//
//  ArcXPContentTests.swift
//  ArcXPContentTests
//
//  Created by Cassandra Balbuena on 1/12/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class ArcXPContentTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
        let config = ArcXPContentConfig(organizationName: "ArcXP", serverEnvironment: .none, site: "site", hostDomain: "thearcxp.com")
        ArcXPContentManager.setUp(configuration: config)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
 
        let orgName = ArcXPContentManager.client.configuration.organizationName
        XCTAssertEqual(orgName, "ArcXP")
    }

    func testLogging() throws {

        // Add logging observer
        let observer = MockLoggingManagerObserver()
        LoggingManager.add(observer: observer)

        // Test standard log message
        LoggingManager.log("Test log.")

        // Test logging at error level
        LoggingManager.log("Test log level error", level: .error)

        // Test logging with metadata
        let metadata = [LoggingManager.Metadata.timestamp,
                        LoggingManager.Metadata.timezone,
                        LoggingManager.Metadata.osVersion,
                        LoggingManager.Metadata.sdkVersion,
                        LoggingManager.Metadata.deviceModel,
                        LoggingManager.Metadata.connectivityState,
                        LoggingManager.Metadata.sourceClass("ArcXPContentTests"),
                        LoggingManager.Metadata.breadcrumbs(["none"]),
                        LoggingManager.Metadata.unspecified(["key": "value"]),
                        LoggingManager.Metadata.platform]
        LoggingManager.log("Test log level debug and metadata",
                           level: .debug,
                           metadata: metadata)
        LoggingManager.log("Warning log", level: .warning)
        LoggingManager.log("Trace log", level: .trace)
        LoggingManager.log("Notice log", level: .notice)
        LoggingManager.log("Critical log", level: .critical)
        // Clear observers
        LoggingManager.clearObservers()
    }
}
