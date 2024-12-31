//
//  SDKInitializer.swift
//  ArcXP
//
//  Created by David Seitz Jr on 2/7/23.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import Foundation
import ArcXP

public struct SDKInitializer {

    /// Configure each available Arc XP service.
    public static func configureArcXPServices() {
        let commerceConfiguration = SubscriptionsConfiguration(baseUrl: "https://\(Constants.Org.commerceDomain)",
                                                          organization: Constants.Org.orgName,
                                                          environment: .sandbox,
                                                          site: Constants.Org.siteName)

        let contentConfiguration = ContentConfiguration(baseUrl: "https://\(Constants.Org.contentDomain)",
                                                        organization: Constants.Org.orgName,
                                                        environment: .sandbox,
                                                        site: Constants.Org.siteName,
                                                        cacheConfiguration: ArcXPCacheConfig())

        let videoConfiguration = VideoConfiguration(organization: Constants.Org.orgName,
                                                    environment: .sandbox,
                                                    enableLivestreamAds: true,
                                                    useGeorestrictions: false)
        Services.configure(service: .subscriptions(commerceConfiguration))
        Services.configure(service: .content(contentConfiguration))
        Services.configure(service: .video(videoConfiguration))
    }
}
