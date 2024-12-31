//
//  DevelopmentGlobals.swift
//  Commerce
//
//  Created by Seitz, David on 6/30/20.
//  Copyright © 2020 The Washington Post Company. All rights reserved.
//

// MARK: - Values

// TODO: AM-4372 - Update SDK development level error prints/logs
/// Determines whether Commerce SDK development only actions should occur or not.
let developmentMode = true

// MARK: - Functions

func devPrint(_ value: Any) {
    if developmentMode {
        print(value)
    }
}

/// Dispatches the given block on the main thread context, switching only if nessessary.
/// - parameter block: The closure to be executed.
func deliverToMainThread(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
    }
}
