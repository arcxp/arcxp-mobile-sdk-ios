//
//  ArcXPContentManagerTests.swift
//  ArcXPTests
//
//  Created by Mahesh Venkateswarlu on 7/14/22.
//  Copyright © 2022 Arc XP. All rights reserved.
//

import XCTest
@testable import ArcXP

class ArcXPContentManagerTests: BaseNetworkTests {
    
    func testOrgConfig() {
        let client = ArcXPContentManager.client
        XCTAssertEqual(client.configuration.hostDomain, "https://arcsales-arcsales-sandbox.web.arc-cdn.net")
        XCTAssertEqual(client.configuration.organizationName, "ArcXP")
        XCTAssertEqual(client.configuration.serverEnvironment, .sandbox)
    }
    
    func testCacheConfig() {
        let config = ArcXPContentConfig(organizationName: "arcsales",
                                        serverEnvironment: .sandbox,
                                        site: "arcsales",
                                        hostDomain: "arcsales-arcsales-sandbox.web.arc-cdn.net")
        let cacheConfig = ArcXPCacheConfig(cacheTimeUntilUpdate: 1.1,
                                           maxCacheSize: 6,
                                           shouldPreloadCache: true)
        ArcXPContentManager.setUp(configuration: config, cacheConfig: cacheConfig)
        
        let client = ArcXPContentManager.client
        XCTAssertEqual(client.cacheConfiguration.cacheTimeUntilUpdate, 1.1)
        XCTAssertEqual(client.cacheConfiguration.maxCacheSize, 6)
        XCTAssertEqual(client.cacheConfiguration.shouldPreloadCache, true)
    }
    
    func testVersionString() {
        let version = ArcXPSDK.version
        XCTAssertEqual(version, "1.3.0")
    }
}
