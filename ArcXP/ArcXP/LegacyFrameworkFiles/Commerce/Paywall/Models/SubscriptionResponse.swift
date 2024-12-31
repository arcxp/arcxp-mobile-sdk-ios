//
//  SubscriptionResponse.swift
//  ArcXPCommerce
//
//  Created by David Seitz Jr on 7/13/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

public typealias SubscriptionsResponse = [SubscriptionSummary]

public struct SubscriptionSummary: Codable {
    public let paymentMethod: PaymentMethod?
    public let productName: String?
    public let sku: String
    public let statusID: Int
    public let subscriptionID: Int
    public let currentRetailCycleIDX: Int?
    public let attributes: [[String: String]]?
}

public struct PaymentMethod: Codable {
    public let cardHolderName: String?
    public let creditCardType: String?
    public let expiration: String?
    public let firstSix: String?
    public let lastFour: String?
    public let paymentPartner: String?
    public let paymentMethodID: Int
}
