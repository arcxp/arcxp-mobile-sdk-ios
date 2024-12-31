//
//  ConfigOptions.swift
//  Commerce
//
//  Created by Davis, Tyler on 5/28/21.
//  Copyright © 2020 The Washington Post Company. All rights reserved.
//

import Foundation

/// Model for login configuration options for the Commerce service.
public struct ConfigOptions: Codable {
    public let signupRecaptcha: Bool
    public let signinRecaptcha: Bool
    public let magicLinkRecaptcha: Bool
    public let recaptchaSiteKey: String
}
