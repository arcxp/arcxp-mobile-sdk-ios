//
//  AccountDeletionDeclineData.swift
//  Commerce
//
//  Created by David Seitz Jr on 5/13/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

/// A data structure containing reasons for declining account deletion.
public enum DeletionDeclineReason: String {

    case mistake = "MISTAKE"
    case changedMind = "CHANGED_MIND"
    case other = "OTHER"

    /// The notes to be associated with each reason.
    var notes: String {
        switch self {
        case .mistake:
            return "The user mistakenly started the account deletion process."
        case .changedMind:
            return "The user changed their mind about deleting their account."
        case .other:
            return "The user has another reason for declining to delete their account."
        }
    }
}
