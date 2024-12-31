//
//  RetailEndpoint.swift
//  ArcXPCommerce
//
//  Created by Davis, Tyler on 7/20/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

// Base URL: https://arctesting1-config-sandbox.api.cdn.arcpublishing.com/retail/public/v1/paywall/active
// Swagger documentation: https://washpost.arcpublishing.com/alc/docs/swagger/?url=./arc-products/arc-retail.json

@available(iOS 13.0, *)
enum RetailEndpoint: Endpoint {
    case paywall

    var baseUrl: String {
        return Subscriptions.configuration.baseUrl+"/retail/public/\(Subscriptions.retailWebAPIVersion.rawValue)"
    }

    var path: String {
        switch self {
        case .paywall:
            return "/paywall/active"
        }
    }

    var method: String {
        return "GET"
    }

    var headers: [String: String]? {
        let standardHeaders = ["Content-Type": ArcXPConstants.contentTypeHeader,
                               "Arc-Organization": Subscriptions.configuration.organization,
                               "Arc-Site": Subscriptions.configuration.site,
                               "User-Agent": ArcXPConstants.userAgentHeader]
        return standardHeaders
    }

    var urlParameters: [String: String]? {
        return nil
    }

    /// The body data to be attached with the relevant Identity request.
    var body: Data? {
        return nil
    }

}
