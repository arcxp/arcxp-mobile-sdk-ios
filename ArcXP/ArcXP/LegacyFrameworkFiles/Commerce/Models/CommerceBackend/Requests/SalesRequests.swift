//
//  SalesRequests.swift
//  ArcXPCommerce
//
//  Created by David Seitz Jr on 10/19/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

struct SalesAddress: Codable {
    // Note: This is siimlar to UserProfile.Address, but differs in the properties included.
    let line1: String
    let line2: String
    let city: String
    let state: String
    let country: String
    let zipCode: String

    enum CodingKeys: String, CodingKey {
        case line1, line2, country
        case city = "locality"
        case state = "region"
        case zipCode = "postal"
    }
}

struct FinalizePaymentMethodUpdateRequest: Codable {
    let token: String
    let email: String
    let address: SalesAddress
    let phone: String
    let browserInfo: String
    let firstName: String
    let lastName: String
}

struct ShareSubscriptionRequest: Codable {
    let email: String
}

struct RedeemSubscriptionRequest: Codable {
    let token: String
}

struct SetRecipientForGiftSubscriptionRequest: Codable {
    let email: String
    let name: String
    let note: String
    let sendNotificationOn: String
}

struct JoinGroupSubscriptionRequest: Codable {
    let accessCode: String
}

struct NotifySuccessfulSwgPurchaseRequest: Codable {
    let orderID: String
    let packageName: String
    let productID: String
    let purchaseTime: Int
    let purchaseState: Int
    let purchaseToken: String
    let autoRenewing: Bool
    let findOrCreate: Bool

    enum CodingKeys: String, CodingKey {
        case orderID = "orderId"
        case productID = "productId"
        case packageName, purchaseTime, purchaseState, purchaseToken, autoRenewing, findOrCreate
    }
}

struct AddRampReaderIdRequest: Codable {
    let ampReaderID: String
    enum CodingKeys: String, CodingKey { case ampReaderID = "ampReaderId" }
}

struct AddToCartRequest: Codable {
    let items: [CartItem]
    let billingAddress: SalesAddress

    struct CartItem: Codable {
        let sku: String
        let priceCode: String
        let quantity: Int
        let campaignCode: String
    }
}
