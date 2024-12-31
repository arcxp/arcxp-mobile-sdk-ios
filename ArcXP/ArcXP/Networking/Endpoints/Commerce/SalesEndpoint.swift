//
//  SalesEndpoint.swift
//  ArcXPCommerce
//
//  Created by Davis, Tyler on 7/23/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

// Base url: https://arctesting1-config-sandbox.api.cdn.arcpublishing.com/sales/public/v1
// Swagger documentation: https://washpost.arcpublishing.com/alc/docs/swagger/?url=./arc-products/arc-sales.json

@available(iOS 13.0, *)

enum SalesEndpoint: Endpoint {

    static var salesID: Int?
    static var paymentMethodID: Int? // Also referred to as "pid".

    // MARK: Payment method interaction
    
    case updatePaymentMethod
    case finalizePaymentMethodUpdate(_ request: FinalizePaymentMethodUpdateRequest)

    // MARK: Subscription Interaction
    
    case allActiveSubscriptions
    case subscriptionDetails
    case subscriptionSharingDetails
    case stopSharingSubscription
    case shareSubscription(_ request: ShareSubscriptionRequest)
    case redeemSubscriptionInvitation(_ request: RedeemSubscriptionRequest)
    case allSubscriptions
    case rescueSubscription
    case setRecipientForGiftSubscription(_ redeemCode: String, _ request: SetRecipientForGiftSubscriptionRequest)
    case redeemGiftSubscription(_ request: RedeemSubscriptionRequest)

    // MARK: Email Group Subscription

    case removeGroupSubscriptionMember(_ groupID: Int, _ subscriptionID: Int)
    case joinGroupSubscription(_ request: JoinGroupSubscriptionRequest)
    case allSubscriptionGroups
    case allSubscriptionGroupMembers(_ accessCode: Int)

    // MARK: Entitlement Interaction

    case entitlements

    // MARK: Order Interaction

    case orderHistory

    // MARK: SwG Interaction

    case swgEntitlements(_ accessToken: String)
    case notifySuccessfulSwgPurchase(_ request: NotifySuccessfulSwgPurchaseRequest)
    case loginExists
    case pubSub
    case ampReaderIDs
    case addAmpReaderID(_ request: AddRampReaderIdRequest)

    // MARK: - Endpoint Values

    var baseUrl: String {
        return Subscriptions.configuration.baseUrl+"/sales/public/\(Subscriptions.salesWebAPIVersion.rawValue)"
    }

    var path: String {
        switch self {

            // Payment Method Interaction

        case .updatePaymentMethod:
            guard let salesID = SalesEndpoint.salesID, let paymentMethodID = SalesEndpoint.paymentMethodID else { return "" }
            return "/paymentmethod/\(salesID)/provider/\(paymentMethodID)"

        case .finalizePaymentMethodUpdate:
            guard let salesID = SalesEndpoint.salesID, let paymentMethodID = SalesEndpoint.paymentMethodID else { return "" }
            return "/paymentmethod/\(salesID)/provider/\(paymentMethodID)/finalize"

        case .allActiveSubscriptions:
            return "/subscription/allactive"

        case .subscriptionDetails:
            guard let salesID = SalesEndpoint.salesID else { return "" }
            return "/subscription/\(salesID)/details"

        case .subscriptionSharingDetails:
            guard let salesID = SalesEndpoint.salesID else { return "" }
            return "/subscription/\(salesID)/sharing"

        case .stopSharingSubscription:
            guard let salesID = SalesEndpoint.salesID else { return "" }
            return "/subscription/\(salesID)/stopshare"

        case .shareSubscription:
            guard let salesID = SalesEndpoint.salesID, SalesEndpoint.paymentMethodID != nil else { return "" }
            return "/subscription/\(salesID)/share"

        case .redeemSubscriptionInvitation:
            return "/subscription/redeem"

        case .allSubscriptions:
            return "/subscription/all"

        case .rescueSubscription:
            guard let salesID = SalesEndpoint.salesID else { return "" }
            return "subscription/\(salesID)/rescue"

        case .setRecipientForGiftSubscription(let redeemCode, _):
            return "/subscription/gift/\(redeemCode)"

        case .redeemGiftSubscription(_):
            return "/subscription/gift/redeem"

            // Email Group Subscription Management

        case .removeGroupSubscriptionMember(let groupID, let subscriptionID):
            return "/emailgroupsub/\(groupID)/\(subscriptionID)"

        case .joinGroupSubscription:
            return "/emailgroupsub/join"

        case .allSubscriptionGroups:
            return "/emailgroupsub/getAll"

        case .allSubscriptionGroupMembers(let accessCode):
            return "/emailgroupsub/\(accessCode)/getAllMembers"

            // Entitlement Interaction

        case .entitlements:
            return "/entitlements"

            // Order Interaction

        case .orderHistory:
            return "/order/history"

            // SwG Interaction

        case .swgEntitlements:
            return "/swg/entitlements"

        case .notifySuccessfulSwgPurchase:
            return "/swg/purchase"

        case .loginExists:
            return "/swg/loginexists"

        case .pubSub:
            return "/swg/pubsub"

        case .ampReaderIDs:
            return "/amp"

        case .addAmpReaderID:
            return "amp/add"
        }
    }

    var method: String {
        switch self {

        case .finalizePaymentMethodUpdate,
             .stopSharingSubscription,
             .shareSubscription,
             .rescueSubscription,
             .setRecipientForGiftSubscription,
             .addAmpReaderID:
            return "PUT"

        case .redeemSubscriptionInvitation,
             .redeemGiftSubscription,
             .joinGroupSubscription,
             .notifySuccessfulSwgPurchase,
             .loginExists,
             .pubSub:
            return "POST"

        case .removeGroupSubscriptionMember:
            return "DELETE"

        default:
            return "GET"
        }
    }

    var headers: [String: String]? {
        var standardHeaders = ["Content-Type": ArcXPConstants.contentTypeHeader,
                               "Arc-Organization": Subscriptions.configuration.organization,
                               "Arc-Site": Subscriptions.configuration.site,
                               "User-Agent": ArcXPConstants.userAgentHeader]
        if let accessToken = Subscriptions.Identity.accessToken {
            standardHeaders["Authorization"] = "Bearer \(accessToken)"
        }
        return standardHeaders
    }

    var urlParameters: [String: String]? {
        return nil
    }

    /// The body data to be attached with the relevant Identity request.
    var body: Data? {

        switch self {

        case .finalizePaymentMethodUpdate(let request):
            return request.toJSONData()

        case .shareSubscription(let request):
            return request.toJSONData()

        case .redeemSubscriptionInvitation(let request):
            return request.toJSONData()

        case .setRecipientForGiftSubscription(_, let request):
            return request.toJSONData()

        case .redeemGiftSubscription(let request):
            return request.toJSONData()

        case .joinGroupSubscription(let request):
            return request.toJSONData()

        case .notifySuccessfulSwgPurchase(let request):
            return request.toJSONData()

        case .addAmpReaderID(let request):
            return request.toJSONData()

        default:
            return nil
        }
    }
}
