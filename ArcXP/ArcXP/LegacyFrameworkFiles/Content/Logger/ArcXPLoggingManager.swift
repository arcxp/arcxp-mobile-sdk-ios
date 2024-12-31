//
//  LoggingManager.swift
//  ArcXPCommerce
//
//  Created by David Seitz Jr on 1/31/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import UIKit

/// A manager for Content specific log messages.
public struct LoggingManager {

    // Note: Analagous types have been created here to abstract `Logging`
    // and prevent the need for the client to import Logging alongside our framework.

    /// Specific metadata values which can be provided when logging events.
    public enum Metadata {
        /// The timestamp of the log.
        case timestamp

        /// The current os version to be logged.
        case osVersion

        /// The current SDK version to be logged.
        case sdkVersion

        /// The device model that the SDK is running on.
        case deviceModel

        /// The state of connectivity when the log is made.
        case connectivityState

        /// The timezone that the log is made in.
        case timezone

        /// The class from which the log event is being made.
        case sourceClass(_ sourceClass: String)

        /// A collection of actions leading to the event that is being logged.
        case breadcrumbs(_ breadcrumbs: [String])

        /// Metadata that is not specified. Stored in the given `dictionary`.
        case unspecified(_ dictionary: [String: String])

        /// The platform the SDK is running on when the log is made.
        case platform

        /// Metadata separated into keys and values for easy logging.
        fileprivate var entry: (key: String, value: Logger.MetadataValue) {

            switch self {
            case .timestamp:
                return ("timestamp", .string("\(Date())"))

            case .osVersion:
                return ("osVersion", .string(UIDevice.current.systemVersion))

            case .sdkVersion:
                let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "N/A"
                return ("sdkVersion", .string(version))

            case .deviceModel:
                return ("deviceModel", .string(UIDevice.current.modelName))

            case .connectivityState:
                return ("connectivityState", .string("Is connected to network: \(Reachability.isConnectedToNetwork)"))

            case .timezone:
                return ("timezone", "Seconds from GMT: \(TimeZone.current.secondsFromGMT())")

            case .sourceClass(let sourceClass):
                return ("sourceClass", .string(sourceClass))

            case .breadcrumbs(let breadcrumbs):
                let metadataValue: [Logger.MetadataValue] = breadcrumbs.map { Logger.MetadataValue.string($0) }
                return ("breadcrumb", .array(metadataValue))

            case .unspecified(let dictionary):
                var metadataDictionary: Logger.Metadata = [String: Logger.MetadataValue]()
                for value in dictionary {
                    metadataDictionary[value.key] = Logger.MetadataValue.string(value.value)
                }
                return ("unspecified", .dictionary(metadataDictionary))

            case .platform:
                // Generically providing "apple" instead of "iOS" in case this SDK
                // gets used on other Apple platforms, including iPadOS, macOS, and tvOS.
                return ("platform", "apple")
            }
        }
    }

    /// Levels at which messages can be logged.
    public enum Level: String {

        // Note: This is pulled from `Logging` to prevent the need for the client
        // to import `Logging` themselves.

        /// Appropriate for messages that contain information normally of use only when
        /// tracing the execution of a program.
        case trace

        /// Appropriate for messages that contain information normally of use only when
        /// debugging a program.
        case debug

        /// Appropriate for informational messages.
        case info

        /// Appropriate for conditions that are not error conditions, but that may require
        /// special handling.
        case notice

        /// Appropriate for messages that are not error conditions, but more severe than
        /// `.notice`.
        case warning

        /// Appropriate for error conditions.
        case error

        /// Appropriate for critical error conditions that usually require immediate
        /// attention.
        ///
        /// When a `critical` message is logged, the logging backend (`LogHandler`) is free to perform
        /// more heavy-weight operations to capture system state (such as capturing stack traces) to facilitate
        /// debugging.
        case critical

        /// Provides the abstracted `Logging` version of these log levels.
        fileprivate func loggingAnalog() -> Logger.Level {
            switch self {
            case .trace:
                return .trace
            case .debug:
                return .debug
            case .info:
                return .info
            case .notice:
                return .notice
            case .warning:
                return .warning
            case .error:
                return .error
            case .critical:
                return .critical
            }
        }
    }

    /// An abstracted shared instance, which allows logging functionality to be kept at the struct level,
    /// eliminating the need to create and manage instances of this struct.
    private static var shared = LoggingManager()

    /// A `Logging` logger instance for handling core logging functionality.
    private var logger = Logger(label: "com.arcxp.ContentSDK")

    /// A collection of observers which logs will be reported to. This is a collection rather than a single delegate so that
    /// multiple parts of an app can listen for updates and handle/report them as needed.
    private var observers = [LoggingManagerObserver]()
// swiftlint: disable unneeded_synthesized_initializer
    private init() {
        // Initialization made private to prevent unnecessary reinstantiation.
    }
// swiftlint: enable unneeded_synthesized_initializer
    /// Log a new message.
    /// - parameter message: The message to be logged.
    /// - parameter level: The level at which this message should be logged.
    /// - parameter metadata: Additional metadata that can be provided with each log.
    public static func log(_ message: String,
                           level: LoggingManager.Level = .info,
                           metadata metadataValues: [LoggingManager.Metadata] = [LoggingManager.Metadata]()) {
        var metadata = Logger.Metadata()

        // Always include platform, unless it has been manually included.
        if !metadataValues.contains(where: { $0.entry.key == "platform" }) {
            metadata["platform"] = LoggingManager.Metadata.platform.entry.value
        }

        // Add metadata
        for item in metadataValues { metadata[item.entry.key] = item.entry.value }

        // Make the log
        shared.logger.log(level: level.loggingAnalog(), "\(message)", metadata: metadata)

        // Report the log
        for observer in shared.observers {
            observer.loggingManagerDidReportLog(message: message, level: level, metadata: metadataValues)
        }
    }

    // MARK: Observers Management

    /// Add an observer to listen and respond to message logs.
    /// - parameter observer: The logging observer to be added.
    public static func add(observer: LoggingManagerObserver) {
        shared.observers.append(observer)
    }

    /// Clears any observers that have been previously added.
    public static func clearObservers() {
        shared.observers = [LoggingManagerObserver]()
    }
}

// MARK: - LoggingManagerObserver

public protocol LoggingManagerObserver {
    /// Reports any logs that have been sent to the LoggingManager.
    /// - parameter message: The message that was logged.
    /// - parameter level: The level at which the logged happened.
    /// - parameter metadata: Any additional metadata included with the log.
    func loggingManagerDidReportLog(message: String, level: LoggingManager.Level, metadata: [LoggingManager.Metadata]?)
}
