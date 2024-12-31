//
//  SalesEndpointTests.swift
//  ArcXPTests
//
//  Created by David Seitz on 1/24/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class SalesEndpointTests: XCTestCase {

    private static let testSalesID: Int = 123
    private static let testPaymentMethodID: Int = 456

    func testIDValuesNil() {
        var originalSalesID: Int?
        var originalPaymentMethodID: Int?

        if let salesID = SalesEndpoint.salesID {
            originalSalesID = salesID
            SalesEndpoint.salesID = nil
        }

        if let paymentMethodID = SalesEndpoint.paymentMethodID {
            originalPaymentMethodID = paymentMethodID
            SalesEndpoint.paymentMethodID = nil
        }

        // These paths rely on an existing salesID and/or paymentMethodID
        let updatePaymentMethodPath = SalesEndpoint.updatePaymentMethod.path
        XCTAssertEqual(updatePaymentMethodPath, "")

        let subscriptionDetailsPath = SalesEndpoint.subscriptionDetails.path
        XCTAssertEqual(subscriptionDetailsPath, "")

        let subscriptionSharingDetails = SalesEndpoint.subscriptionSharingDetails.path
        XCTAssertEqual(subscriptionSharingDetails, "")

        let stopSharingSubscriptionPath = SalesEndpoint.stopSharingSubscription.path
        XCTAssertEqual(stopSharingSubscriptionPath, "")

        let rescueSubscriptionPath = SalesEndpoint.rescueSubscription.path
        XCTAssertEqual(rescueSubscriptionPath, "")

        // Restore original values
        SalesEndpoint.salesID = originalSalesID
        SalesEndpoint.paymentMethodID = originalPaymentMethodID
    }

    func testIDValuesPresent() {

        if SalesEndpoint.salesID == nil {
            SalesEndpoint.salesID = SalesEndpointTests.testSalesID
        }

        if SalesEndpoint.paymentMethodID == nil {
            SalesEndpoint.paymentMethodID = SalesEndpointTests.testPaymentMethodID
        }

        guard
            let salesID = SalesEndpoint.salesID,
            let paymentMethodID = SalesEndpoint.paymentMethodID else {
            XCTFail("Expected test ID values were not present.")
            return
        }

        // These paths rely on an existing salesID and/or paymentMethodID
        let updatePaymentMethodPath = SalesEndpoint.updatePaymentMethod.path
        XCTAssertEqual(updatePaymentMethodPath, "/paymentmethod/\(salesID)/provider/\(paymentMethodID)")

        let subscriptionDetailsPath = SalesEndpoint.subscriptionDetails.path
        XCTAssertEqual(subscriptionDetailsPath, "/subscription/\(salesID)/details")

        let subscriptionSharingDetails = SalesEndpoint.subscriptionSharingDetails.path
        XCTAssertEqual(subscriptionSharingDetails, "/subscription/\(salesID)/sharing")

        let stopSharingSubscriptionPath = SalesEndpoint.stopSharingSubscription.path
        XCTAssertEqual(stopSharingSubscriptionPath, "/subscription/\(salesID)/stopshare")

        let rescueSubscriptionPath = SalesEndpoint.rescueSubscription.path
        XCTAssertEqual(rescueSubscriptionPath, "subscription/\(salesID)/rescue")

        // If test values were needed, restore to nil
        if SalesEndpoint.salesID == SalesEndpointTests.testSalesID { SalesEndpoint.salesID = nil }
        if SalesEndpoint.paymentMethodID == SalesEndpointTests.testPaymentMethodID { SalesEndpoint.paymentMethodID = nil }
    }

    /// These endpoints are simpler to test, because they only involve a String comparisson, and/or provided parameter values.
    func testSimpleSalesEndpointPaths() {

        let allActiveSubscritionsPath = SalesEndpoint.allActiveSubscriptions.path
        XCTAssertEqual(allActiveSubscritionsPath, "/subscription/allactive")

        let allSubscriptionsPath = SalesEndpoint.allSubscriptions.path
        XCTAssertEqual(allSubscriptionsPath, "/subscription/all")

        let testGroupID = 123
        let testSubscriptionID = 456
        let removeGroupSubscriptionMemberPath = SalesEndpoint.removeGroupSubscriptionMember(testGroupID, testSubscriptionID).path
        XCTAssertEqual(removeGroupSubscriptionMemberPath, "/emailgroupsub/\(testGroupID)/\(testSubscriptionID)")

        let allSubscriptionGroupsPath = SalesEndpoint.allSubscriptionGroups.path
        XCTAssertEqual(allSubscriptionGroupsPath, "/emailgroupsub/getAll")

        let testAccessCode = 123
        let allSubscriptionGroupMembersPath = SalesEndpoint.allSubscriptionGroupMembers(testAccessCode).path
        XCTAssertEqual(allSubscriptionGroupMembersPath, "/emailgroupsub/\(testAccessCode)/getAllMembers")

        let entitlementsPath = SalesEndpoint.entitlements.path
        XCTAssertEqual(entitlementsPath, "/entitlements")

        let orderHistoryPath = SalesEndpoint.orderHistory.path
        XCTAssertEqual(orderHistoryPath, "/order/history")

        let testSwgEntitlementsAccessToken = "TestSwgEntitlementsAccessToken"
        let swgEntitlementsPath = SalesEndpoint.swgEntitlements(testSwgEntitlementsAccessToken).path
        XCTAssertEqual(swgEntitlementsPath, "/swg/entitlements")

        let loginExistsPath = SalesEndpoint.loginExists.path
        XCTAssertEqual(loginExistsPath, "/swg/loginexists")

        let pubSubPath = SalesEndpoint.pubSub.path
        XCTAssertEqual(pubSubPath, "/swg/pubsub")
        
        let ampReaderIDsPath = SalesEndpoint.ampReaderIDs.path
        XCTAssertEqual(ampReaderIDsPath, "/amp")
    }

    // These are remaining commented out for now to target other tests that will be faster to complete.
//    func testEndpointsWithRequestParameters() {
//        let finalizePaymentMethodPath = SalesEndpoint.finalizePaymentMethodUpdate(<#T##request: FinalizePaymentMethodUpdateRequest##FinalizePaymentMethodUpdateRequest#>)
//        let shareSubscription = SalesEndpoint.shareSubscription(<#T##request: ShareSubscriptionRequest##ShareSubscriptionRequest#>)
//        let redeemSubscriptionInvitation = SalesEndpoint.redeemSubscriptionInvitation(<#T##request: RedeemSubscriptionRequest##RedeemSubscriptionRequest#>)
//        let setRecipientForGiftSubscriptionPath = SalesEndpoint.setRecipientForGiftSubscription(<#T##redeemCode: String##String#>, <#T##request: SetRecipientForGiftSubscriptionRequest##SetRecipientForGiftSubscriptionRequest#>)
//        let joinGroupSubscriptionPath = SalesEndpoint.joinGroupSubscription(<#T##request: JoinGroupSubscriptionRequest##JoinGroupSubscriptionRequest#>)
//        let redeemGiftSubscription = SalesEndpoint.redeemGiftSubscription(<#T##request: RedeemSubscriptionRequest##RedeemSubscriptionRequest#>)
//        let notifySuccessfulSwgPurchasePath = SalesEndpoint.notifySuccessfulSwgPurchase(<#T##request: NotifySuccessfulSwgPurchaseRequest##NotifySuccessfulSwgPurchaseRequest#>)
//        let addAmpReaderIDPath = SalesEndpoint.addAmpReaderID(<#T##request: AddRampReaderIdRequest##AddRampReaderIdRequest#>)
//    }
}
