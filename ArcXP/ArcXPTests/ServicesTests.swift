//
//  ServicesTests.swift
//  ArcXPTests
//
//  Created by David Seitz on 12/6/23.
//  Copyright © 2023 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class ServicesTests: XCTestCase {
    
    func testConfigureServices() {

        let commerceConfiguration = SubscriptionsConfiguration(baseUrl: TestConstant.subscriptionsConfigBaseUrl,
                                                               organization: TestConstant.subscriptionsConfigOrg,
                                                               environment: TestConstant.subscriptionsConfigEnv,
                                                               site: TestConstant.subscriptionsConfigSite)

        let contentConfiguration = ContentConfiguration(baseUrl: TestConstant.contentConfigBaseUrl,
                                                        organization: TestConstant.contentConfigOrg,
                                                        environment: TestConstant.contentConfigEnv,
                                                        site: TestConstant.contentConfigSite,
                                                        cacheConfiguration: TestConstant.contentCacheConfig)

        let videoConfiguration = VideoConfiguration(organization: TestConstant.videoConfigOrg,
                                                    environment: TestConstant.videoConfigEnv,
                                                    useGeorestrictions: TestConstant.videoConfigUseGeorestrictions)

        for service in [ArcXPService.subscriptions(commerceConfiguration),
                        ArcXPService.content(contentConfiguration),
                        ArcXPService.video(videoConfiguration)] {
            ArcXP.Services.configure(service: service)
        }

        XCTAssertEqual(Subscriptions.configuration.baseUrl, "https://\(TestConstant.subscriptionsConfigBaseUrl)")
        XCTAssertEqual(Subscriptions.configuration.organization, TestConstant.subscriptionsConfigOrg)
        XCTAssertEqual(Subscriptions.configuration.environment, TestConstant.subscriptionsConfigEnv.rawValue)
        XCTAssertEqual(String(ArcXPContentManager.client.configuration.hostDomain.dropFirst(8)), TestConstant.contentConfigBaseUrl)
        XCTAssertEqual(ArcXPContentManager.client.configuration.organizationName, TestConstant.contentConfigOrg)
        XCTAssertEqual(ArcXPContentManager.client.configuration.serverEnvironment, TestConstant.contentConfigEnv)
        XCTAssertEqual(ArcXPContentManager.client.configuration.site, TestConstant.contentConfigSite)
        XCTAssertEqual(ArcMediaClientManager.client.organizationID, TestConstant.videoConfigOrg)
    }
}
