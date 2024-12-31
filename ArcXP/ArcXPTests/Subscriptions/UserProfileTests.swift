//
//  UserProfileTests.swift
//  ExampleTests
//
//  Created by Cassandra Balbuena on 7/9/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import XCTest
@testable import ArcXP

class UserProfileTests: SubscriptionsMockNetworkTest {

    func testSetUpRequiredFields() {
        var userProfile = UserProfile()
        userProfile.setUp(withRequiredFields: "testUsername", 
                          password: "testPassword",
                          email: "testEmail")
        XCTAssertEqual(userProfile.userName, "testUsername")
        XCTAssertEqual(userProfile.password, "testPassword")
        XCTAssertEqual(userProfile.email, "testEmail")
    }
    
    func testGetUserProfileAPIPathComponents() {
        Subscriptions.mock.mockNetworkResponseEnabled = false
        let profileEndpoint = IdentityEndpoint.profile
        XCTAssertTrue(profileEndpoint.url!.pathComponents.contains("profile"))
        XCTAssertEqual(profileEndpoint.method, "GET")
    }

    func testFetchUserProfile() {
        // Specify the intent for a successful mock data result.
        Subscriptions.mock.result = .success

        // Specify the expectation of this test.
        let networkCallExpectation = expectation(description: "User profile is successfully fetched.")

        // Set up networking details.
        let userProfileEndpoint = IdentityEndpoint.profile
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: userProfileEndpoint.url)
        Subscriptions.Identity.accessToken = TestConstant.mockAccessToken

        // Make mock network call.
        Subscriptions.Identity.fetchUserProfile { result in
            switch result {

            case .success:
                guard let currentUser = Subscriptions.cachedUserProfile else {
                    XCTFail("Failed to save the user details")
                    return
                }

                // Verify expected details are present.
                XCTAssertEqual(currentUser.firstName, TestConstant.mockUserFirstName)
                XCTAssertEqual(currentUser.lastName, TestConstant.mockUserLastName)
                XCTAssertEqual(currentUser.email, TestConstant.mockUserEmail)

            case .failure(let error):
                XCTFail("Couldn't fetch the details : \(error)")
            }

            networkCallExpectation.fulfill()
        }

        wait(for: [networkCallExpectation], timeout: TestConstant.expectationTimeout)
    }

    func testUserProfileApiFailure() {
        Subscriptions.mock.result = .failure
        let apiExpectation = expectation(description: "User profile api fail")
        let userProfileEndpoint = IdentityEndpoint.profile
        MockURLProtocol.requestHandler = mockResponse(statusCode: 401, url: userProfileEndpoint.url)
        Subscriptions.Identity.accessToken = TestConstant.mockAccessToken

        var responseError: Error?
        Subscriptions.Identity.fetchUserProfile { result in
            if case let .failure(error) = result {
                responseError = error
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
        XCTAssertNotNil(responseError)
    }

    func testFetchUserProfileMissingTokenFailure() {

        // Specify intent to use mock data.
        Subscriptions.mock.mockNetworkResponseEnabled = true

        // Set up netowkring details.
        let apiExpectation = expectation(description: "Failed to fetch user profile due to missing access token.")
        var responseError: SubscriptionsError.UserAccountErrorReason?

        // Make mock network request.
        Subscriptions.Identity.fetchUserProfile { result in
            if case let .failure(error) = result {
                switch (error as? SubscriptionsError) {
                case .userAccountError(reason: let reason):
                    if case .noAccessTokenAvailable = reason { responseError = reason }
                default:
                    XCTFail("Should throw a fail response")
                }
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
        XCTAssertNotNil(responseError)
    }

    func testProfileUpdateEndpoint() {
        Subscriptions.mock.mockNetworkResponseEnabled = false
        Subscriptions.Identity.queueUserProfileUpdate(.email(TestConstant.mockUserEmail))
        Subscriptions.Identity.queueUserProfileUpdate(.firstName(TestConstant.mockUserFirstName))
        Subscriptions.Identity.queueUserProfileUpdate(.lastName(TestConstant.mockUserLastName))
        Subscriptions.Identity.queueUserProfileUpdate(.secondLastName(TestConstant.mockUserSecondLastname))
        Subscriptions.Identity.queueUserProfileUpdate(.displayName(TestConstant.mockUserDisplayName))
        let updateUserProfileEndpoint = IdentityEndpoint.updateProfile(updatedUserProfileData: Subscriptions.Identity.queuedUserProfileUpdates)

        XCTAssertTrue(updateUserProfileEndpoint.url!.pathComponents.contains("profile"))

        let userProfileUpdateEndpointBody = try? JSONSerialization.jsonObject(with: updateUserProfileEndpoint.body!,
                                                                              options: .allowFragments) as? [String: String]

        XCTAssertEqual((userProfileUpdateEndpointBody?["email"]), TestConstant.mockUserEmail)
        XCTAssertEqual((userProfileUpdateEndpointBody?["firstName"]), TestConstant.mockUserFirstName)
        XCTAssertEqual((userProfileUpdateEndpointBody?["lastName"]), TestConstant.mockUserLastName)
        XCTAssertEqual((userProfileUpdateEndpointBody?["displayName"]), TestConstant.mockUserDisplayName)
    }

    func testUpdateProfileSuccess() {
        Subscriptions.mock.result = .success
        Subscriptions.cachedUserProfile = UserProfile(userName: TestConstant.mockUsername,
                                                 password: TestConstant.mockUserPassword,
                                                 email: TestConstant.mockUserEmail,
                                                 firstName: TestConstant.mockUserFirstName,
                                                 lastName: TestConstant.mockUserLastName,
                                                 displayName: TestConstant.mockUserDisplayName)

        Subscriptions.Identity.accessToken = TestConstant.mockAccessToken
        Subscriptions.Identity.refreshToken = TestConstant.mockRefreshToken

        let apiExpectation = expectation(description: "User profile was updated successfully")
        
        Subscriptions.Identity.queueUserProfileUpdate(.firstName(TestConstant.mockUserFirstName))
        Subscriptions.Identity.queueUserProfileUpdate(.lastName(TestConstant.mockUserLastName))
        Subscriptions.Identity.queueUserProfileUpdate(.secondLastName(TestConstant.mockUserSecondLastname))
        Subscriptions.Identity.queueUserProfileUpdate(.displayName(TestConstant.mockUserDisplayName))
        Subscriptions.Identity.queueUserProfileUpdate(.email(TestConstant.mockUserEmail))
        Subscriptions.Identity.queueUserProfileUpdate(.birthDay(TestConstant.mockBirthDay))
        Subscriptions.Identity.queueUserProfileUpdate(.birthMonth(TestConstant.mockBirthMonth))
        Subscriptions.Identity.queueUserProfileUpdate(.birthYear(TestConstant.mockBirthYear))
        Subscriptions.Identity.queueUserProfileUpdate(.gender(TestConstant.mockGender))
        Subscriptions.Identity.queueUserProfileUpdate(.picture(TestConstant.mockPictureURL))
        Subscriptions.Identity.queueUserProfileUpdate(.addresses(TestConstant.mockAddresses))
        Subscriptions.Identity.queueUserProfileUpdate(.contacts(TestConstant.mockContacts))

        let updateUserProfileEndpoint = IdentityEndpoint.updateProfile(updatedUserProfileData: Subscriptions.Identity.queuedUserProfileUpdates)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: updateUserProfileEndpoint.url)
        Subscriptions.Identity.commitUserProfileUpdates { result in
            switch result {
            case .success :
                XCTAssertEqual(Subscriptions.cachedUserProfile?.firstName, TestConstant.mockUserFirstName)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.lastName, TestConstant.mockUserLastName)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.secondLastName, TestConstant.mockUserSecondLastname)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.displayName, TestConstant.mockUserDisplayName)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.email, TestConstant.mockUserEmail)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.birthDay, String(TestConstant.mockBirthDay))
                XCTAssertEqual(Subscriptions.cachedUserProfile?.birthMonth, String(TestConstant.mockBirthMonth))
                XCTAssertEqual(Subscriptions.cachedUserProfile?.birthYear, String(TestConstant.mockBirthYear))
                XCTAssertEqual(Subscriptions.cachedUserProfile?.gender, TestConstant.mockGender)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.imageUrlString, TestConstant.mockPictureURL?.absoluteString)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.addresses?.first?.line1, TestConstant.mockAddresses.first?.line1)
                XCTAssertEqual(Subscriptions.cachedUserProfile?.contacts?.first?.phoneNumber, TestConstant.mockContacts.first?.phoneNumber)
            case .failure(let error):
                XCTFail("Failed to update user information = \(error)")
            }
            apiExpectation.fulfill()
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
    func testUserUpdatesQueueClear() {
        Subscriptions.Identity.queueUserProfileUpdate(.displayName(TestConstant.mockUserDisplayName))
        print("Number of queued profile updates is greater than 0: \(Subscriptions.Identity.queuedUserProfileUpdates.count > 0)")
        XCTAssertGreaterThan(Subscriptions.Identity.queuedUserProfileUpdates.count, 0)
        
        Subscriptions.Identity.clearQueuedUserUpdates()
        print("Number of queued user profile updates is equal to 0: \(Subscriptions.Identity.queuedUserProfileUpdates.count == 0)")
        XCTAssertEqual(Subscriptions.Identity.queuedUserProfileUpdates.count, 0)
    }
    
    func testUserAttributeSuccess() {
        Subscriptions.mock.result = .success
        Subscriptions.cachedUserProfile = UserProfile(userName: TestConstant.mockUsername,
                                                 password: TestConstant.mockUserPassword,
                                                 email: TestConstant.mockUserEmail,
                                                 firstName: TestConstant.mockUserFirstName,
                                                 lastName: TestConstant.mockUserLastName,
                                                 displayName: TestConstant.mockUserDisplayName)

        Subscriptions.Identity.accessToken = TestConstant.mockAccessToken
        Subscriptions.Identity.refreshToken = TestConstant.mockRefreshToken

        let apiExpectation = expectation(description: "User Attribute Change")
        let attr = UserProfile.Attribute(name: "key1", value: "value1", type: "String")
        Subscriptions.Identity.queueUserProfileUpdate(.attributes([attr]))
        let updateUserProfileEndpoint = IdentityEndpoint.updateProfile(updatedUserProfileData: Subscriptions.Identity.queuedUserProfileUpdates)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 200, url: updateUserProfileEndpoint.url)
        
        Subscriptions.Identity.commitUserProfileUpdates { result in
            switch result {
            case .success:
                XCTAssertNotNil(Subscriptions.Identity.accessToken, "Failed to save access token")
                XCTAssertNotNil(Subscriptions.Identity.refreshToken, "Failed to save refresh token")
            case .failure(let error):
                XCTFail("User update failed = \(error)")
            }
            apiExpectation.fulfill()
        }

        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }

    func testUpdateProfileFailure() {
        Subscriptions.mock.result = .failure
        let apiExpectation = expectation(description: "User profile update failed")
        let updateUserProfileEndpoint = IdentityEndpoint.updateProfile(updatedUserProfileData: Subscriptions.Identity.queuedUserProfileUpdates)
        MockURLProtocol.requestHandler = mockResponse(statusCode: 400, url: updateUserProfileEndpoint.url)

        Subscriptions.Identity.commitUserProfileUpdates { result in
            if case let .failure(error) = result {
                XCTAssertNotNil(error)
                XCTAssertNotNil(error as? SubscriptionsError)
                let urlRequestError = error as! SubscriptionsError
                switch urlRequestError {
                case .userAccountError(let reason):
                    XCTAssertNotNil(reason)
                default:
                    XCTFail("Should throw a fail response")
                }
                apiExpectation.fulfill()
            }
        }
        wait(for: [apiExpectation], timeout: TestConstant.expectationTimeout)
    }
    
    func testAddContact() {
        let userProfile = UserProfile()
        let contact = UserProfile.Contact(phoneNumber: "1234567890")
        userProfile.addContact(newContact: contact)
        XCTAssertNotNil(userProfile.contacts)
        XCTAssertEqual(userProfile.contacts?.count, 1)
        XCTAssertEqual(userProfile.contacts?.first, contact)
    }

    func testAddAddress() {
        let userProfile = UserProfile()
        let address = UserProfile.Address(line1: "testLine1", city: "testCity")
        userProfile.addAddress(newAddress: address)
        XCTAssertEqual(address.line1, "testLine1")
        XCTAssertEqual(address.city, "testCity")
        XCTAssertNotNil(userProfile.addresses)
        XCTAssertEqual(userProfile.addresses?.count, 1)
        XCTAssertEqual(userProfile.addresses?.first, address)
    }

    func testAddAttribute() {
        let userProfile = UserProfile()
        let attribute = UserProfile.Attribute.init(name: "testName", 
                                                   value: "testValue",
                                                   type: "String")
        userProfile.addAttribute(newAttribute: attribute)
        XCTAssertEqual(attribute.name, "testName")
        XCTAssertEqual(attribute.value, "testValue")
        XCTAssertEqual(attribute.type!.rawValue, "String")
        XCTAssertNotNil(userProfile.attributes)
        XCTAssertEqual(userProfile.attributes?.count, 1)
        XCTAssertEqual(userProfile.attributes?.first, attribute)
    }
    
    func testGenderEnumCoding() {
        let allGenders: [UserProfile.Gender] = [.male, .female, .nonConforming, .preferNotToSay]
        for gender in allGenders {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            do {
                let data = try encoder.encode(gender)
                let decodedGender = try decoder.decode(UserProfile.Gender.self, from: data)
                XCTAssertEqual(gender, decodedGender, "Encoded and decoded gender should be the same")
            } catch {
                XCTFail("Encoding/Decoding for gender \(gender.string) failed with error: \(error)")
            }
        }
    }
    
    func testGenderStringRepresentation() {
        XCTAssertEqual(UserProfile.Gender.male.string, "Male", "String representation of male gender should be 'Male'")
        XCTAssertEqual(UserProfile.Gender.female.string, "Female", "String representation of female gender should be 'Female'")
        XCTAssertEqual(UserProfile.Gender.nonConforming.string, "Non-conforming", "String representation of non-conforming gender should be 'Non-conforming'")
        XCTAssertEqual(UserProfile.Gender.preferNotToSay.string, "Prefer-not-to-say", "String representation of prefer-not-to-say gender should be 'Prefer-not-to-say'")
    }
}
