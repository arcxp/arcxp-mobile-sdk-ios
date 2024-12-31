//
//  EntitlementResponse.swift
//  ArcXPCommerce
//
//  Created by Davis, Tyler on 8/3/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

public struct EntitlementsResponse: Codable {
    public let skus: [EntitlementResponseSKU]? // Example: [{"sku": "33333"}, {"sku": "123456"}]
    public let zones: [Int]? // Example: [1, 2, 3, 4, 5, 6]
    public let edgescape: Edgescape?
}

public struct EntitlementResponseSKU: Codable {
    public let sku: String
}

public struct Edgescape: Codable {
    public let city: String?
    public let continent: String?
    public let geoRegion: String?
    public let dma: String?
    public let countryCode: String?

    var geoElements: [String: String]? {
        var conditions = [String: String]()
        if let city = city {
            conditions["city"] = city
        }
        if let continent = continent {
            conditions["continent"] = continent
        }
        if let geoRegion = geoRegion {
            conditions["georegion"] = geoRegion
        }
        if let dma = dma {
            conditions["dma"] = dma
        }
        if let countryCode = countryCode {
            conditions["country_code"] = countryCode
        }
        return conditions
    }

    enum CodingKeys: String, CodingKey {
        case city, continent, dma
        case geoRegion = "georegion"
        case countryCode = "country_code"
    }
}
