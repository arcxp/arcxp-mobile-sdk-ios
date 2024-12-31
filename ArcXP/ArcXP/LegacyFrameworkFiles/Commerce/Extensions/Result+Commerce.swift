//
//  Result+Commerce.swift
//  Commerce
//
//  Created by Davis, Tyler on 5/19/21.
//  Copyright © 2021 The Washington Post Company. All rights reserved.
//

import Foundation

extension Result where Success == Void {
    static var success: Result {
        return .success(())
    }
}
