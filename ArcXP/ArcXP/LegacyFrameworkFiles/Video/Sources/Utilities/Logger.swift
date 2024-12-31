//  Copyright © 2020 The Washington Post. All rights reserved.
//

import Foundation

/// Logs messages using `NSLog()`. The log level can be set to one of the
/// values in `Logger.Level`; the default level is `.urlRequests`, which also
/// includes errors.
public class ArcXPLogger {

    /// The amount of logging information that should be printed, increasing
    /// from `off` to `all`. Each level also includes every level below it
    /// (numerically), e.g. `urlRequests` also includes `errors`.
    public enum Level: Int, CaseIterable, Comparable {
        // Each case is given an explicit Int value (even though they're the
        // same values that would be generated implicitly) to emphasize that
        // the levels are compared numerically and must be in this order.

        /// Ignore all logging information.
        case off = 0

        /// Print error messages.
        case error = 1

        /// Print URL request and response messages.
        case urlRequests = 2

        /// Print all logging information.
        case all = 3

        /// Compare two log levels. The lower the number, the less information
        /// will be printed to the log.
        public static func < (lhs: ArcXPLogger.Level, rhs: ArcXPLogger.Level) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

    }

    /// The desired logging level. The default is `.urlRequests`, which also
    /// includes all errors.
    public static var level: Level = .urlRequests

    /// Logs the message of String type
    /// - Parameters:
    ///   - message: string value to be logged
    /// - parameter function: The name of the function where this was called.
    /// - parameter file: The name of the file that the caller is found in.
    ///   This will print only the final element in the file path, if the path
    ///   is `/`-separated.
    /// - parameter line: The line on which this call was made.
    ///
    /// - returns: The message string, or `nil` if the log level isn't `all`.
    @discardableResult
    public static func log(_ message: String,
                           function: String = #function,
                           file: String = #file,
                           line: UInt = #line) -> String? {
        if ArcXPLogger.level == .all {
            return internalLog(message, function: function, file: file, line: line)
        } else {
            return nil
        }
    }

    /// Log an `Error` if the `Logger.level` is `.errors` or above.
    ///
    /// - parameter message: The error description. If it's `nil`, then
    ///   the error's own `localizedDescription` will be used.
    /// - parameter error: The error. Its `localizedDescription` _and_ the
    ///   entire error itself will be part of the log message.
    /// - parameter function: The name of the function where this was called.
    /// - parameter file: The name of the file that the caller is found in.
    ///   This will print only the final element in the file path, if the path
    ///   is `/`-separated.
    /// - parameter line: The line on which this call was made.
    ///
    /// - returns: The message string, or `nil` if the log level doesn't include
    ///   errors.
    @discardableResult
    public static func log(_ message: String? = nil,
                           error: Error,
                           function: String = #function,
                           file: String = #file,
                           line: UInt = #line) -> String? {
        if ArcXPLogger.level >= .error {
            let message = """
            ERROR: \(message ?? error.localizedDescription)\n
            \(error)
            """

            return internalLog(message, function: function, file: file, line: line)
        } else {
            return nil
        }
    }

    /// Log errors with the give set of parameters
    /// - parameter message: error message
    /// - parameter description: error description
    /// - parameter statusCode: error status code
    /// - parameter function: The name of the function where this was called.
    /// - parameter file: The name of the file that the caller is found in.
    ///   This will print only the final element in the file path, if the path
    ///   is `/`-separated.
    /// - parameter line: The line on which this call was made.
    ///
    /// - returns: The message string, or `nil` if the log level doesn't include
    ///   errors.
    @discardableResult
    public static func logHTTPError(_ message: String,
                                    description: String,
                                    statusCode: Int = 0,
                                    function: String = #function,
                                    file: String = #file,
                                    line: UInt = #line) -> String? {
        if ArcXPLogger.level >= .error {
            let message = "ERROR: \(message) \n" +
                "ERROR description: \(description) \n" +
                "Status Code: \(statusCode)"
            return internalLog(message, function: function, file: file, line: line)
        } else {
            return nil
        }
    }

    /// Log a message if an object is `nil`. This is handy to check for `[weak
    /// self]` or `[unowned self]`s that have gone out of scope before the
    /// block in which they're used is called.
    ///
    /// - parameter thing: The object being checked.
    /// - parameter function: The name of the function where this was called.
    /// - parameter file: The name of the file that the caller is found in.
    ///   This will print only the final element in the file path, if the path
    ///   is `/`-separated.
    /// - parameter line: The line on which this call was made.
    ///
    /// - returns: The message string, or `nil` if the log level isn't `all`.
    @discardableResult
    public static func logIfNil<T>(_ thing: T?,
                                   function: String = #function,
                                   file: String = #file,
                                   line: UInt = #line) -> String? {
        if ArcXPLogger.level == .all && thing == nil {
            return internalLog("Found an unexpected nil reference.",
                               function: function,
                               file: file,
                               line: line)
        } else {
            return nil
        }
    }

    /// Logs the url, headers and body of the request
    /// - Parameters:
    ///   - urlRequest: request to be logged
    /// - parameter function: The name of the function where this was called.
    /// - parameter file: The name of the file that the caller is found in.
    ///   This will print only the final element in the file path, if the path
    ///   is `/`-separated.
    /// - parameter line: The line on which this call was made.
    ///
    /// - returns: The message string, or `nil` if the log level doesn't include
    ///   `.urlRequests`.
    @discardableResult
    public static func logRequest(urlRequest: URLRequest,
                                  function: String = #function,
                                  file: String = #file,
                                  line: UInt = #line) -> String? {
        if ArcXPLogger.level >= .urlRequests {
            let endPoint = urlRequest.url?.absoluteString ?? ""
            var message = "Request url: \(endPoint) \n"

            if let requestHeaders = urlRequest.allHTTPHeaderFields,
               requestHeaders.keys.count > 0 {
                message.append("\tHTTP headers: ")
                message.append(requestHeaders.map { "\($0): \($1)" }.joined(separator: ", "))
                message.append("\n")
            }

            if let httpBody = urlRequest.httpBody,
               let bodyString = String(data: httpBody, encoding: .utf8) {
                message.append("\tRequest body: \(bodyString)\n")
            }

            return internalLog(message, function: function, file: file, line: line)
        } else {
            return nil
        }
    }

    // MARK: - Internal Functions

    /// Format the message string with the function name, filename, and line
    /// number where the caller was called. The formatted string is logged with
    /// `NSLog()` and returned.
    ///
    /// - parameter function: The name of the function where the *caller* was
    ///   called.
    /// - parameter file: The name of the file that the caller is found in.
    ///   This will print only the final element in the file path, if the path
    ///   is `/`-separated.
    ///
    /// - returns: The message string.
    @discardableResult
    private static func internalLog(_ message: String,
                                    function: String,
                                    file: String,
                                    line: UInt) -> String {
        let filename = file.split(separator: "/").last ?? "unknown file"

        var logMessage = "\(message) \n" +
            "\(function) (\(filename):\(line))"

        if logMessage.count > 1000 {
            logMessage = "\(logMessage.dropFirst(1000))..."
        }

        #if DEBUG
        print(logMessage)
        #endif

        NSLog(logMessage)

        return logMessage
    }

}
