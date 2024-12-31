//
//  SalesResponses.swift
//  ArcXPCommerce
//
//  Created by David Seitz Jr on 10/26/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

typealias AllActiveSubscriptionsResponse = [ActiveSubscription]

struct ActiveSubscription: Codable {
    var subscriptionID: Int
    var sku: String
    var statusID: Int
    var paymentMethod: PaymentMethodResponse?
    var productName: String?
    var attributes: [SubscriptionAttribute]?
    var currentRetailCycleIDX: Int?
}

struct PaymentMethodResponse: Codable {
    var creditCardType: String?
    var firstSix: String?
    var lastFour: String?
    var expiration: String?
    var cardHolderName: String?
    var identificationNumber: String?
    var documentType: String?
    var paymentPartner: String?
    let paymentMethodID: Int
}

struct SubscriptionAttribute: Codable {
    let key: String
    let value: String
}
