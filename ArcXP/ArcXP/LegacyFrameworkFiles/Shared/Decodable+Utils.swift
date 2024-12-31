//  Copyright © 2019 The Washington Post Company. All rights reserved.

import Foundation

/// Custom types for JSON decoding issues.
enum JSONDecodingError: Error {

    // The JSON file couldn't be found in the specified bundle.
    case fileNotFound(filename: String, bundle: Bundle)

}

extension Decodable {

    /// Inverts `JSONDecoder().decode(_:from:)` so that you can simply say
    /// `Decodable.decode(jsonData: data)`. While it's not _that_ useful, it
    /// keeps things in line with the `Decodable.decode(jsonURL:decoder:)` call
    /// below.
    ///
    /// - parameter jsonData: The `Data` to be parsed. If it doesn't contain
    ///             valid JSON data, then an error is thrown.
    /// - parameter decoder: The `JSONDecoder` object to use. The default value
    ///             is a decoder that expects JSON keys to be `camelCase`, not
    ///             `snake_case`.
    ///
    /// - returns:  A parsed `T` object.
    ///
    /// - throws:   A `Foundation.DecodingError` if the data is malformed, a
    ///             non-`Optional` key or value isn't found, or if the value
    ///             isn't the expected type.
    static func decode<T: Decodable>(jsonData: Data,
                                     decoder: JSONDecoder = JSONDecoder()) throws -> T {
        return try decoder.decode(T.self, from: jsonData)
    }

    /// Downloads and parses the JSON data at a specified `URL`.
    ///
    /// - parameter jsonURL: The `URL` to some JSON data.
    /// - parameter decoder: The `JSONDecoder` object to use. The default value
    ///             is a decoder that expects JSON keys to be `camelCase`, not
    ///             `snake_case`.
    ///
    /// - returns:  A parsed `T` object.
    ///
    /// - throws:   A `Foundation.DecodingError` if the data is malformed, a
    ///             non-`Optional` key or value isn't found, or if the value
    ///             isn't the expected type.
    static func decode<T: Decodable>(jsonURL: URL,
                                     decoder: JSONDecoder = JSONDecoder()) throws -> T {
        let data = try Data(contentsOf: jsonURL)

        return try decode(jsonData: data, decoder: decoder)
    }

    /// Get the parsed `Codable` from the specified file (whose name must end
    /// in `.json`, but which should not be included in the filename that's
    /// passed in), or an empty list if there was a problem decoding them or
    /// the file couldn't be found.
    ///
    /// - parameter fromJsonFilename: The name of the `.json` file in specified
    ///             bundle. Do **not** include the `.json` filename extension
    ///             in the string that you pass in!
    /// - parameter inBundle: The bundle that the file is located in. If none
    ///             is specified, then `Bundle.main` will be used.
    /// - parameter decoder: The JSON decoder. Use this to pass in a decoder
    ///             that converts keys from snake case to CamelCase, for
    ///             example.
    ///
    /// - returns:  The decoded object that's parsed from the file.
    static func decode<T: Decodable>(fromJSONFilename jsonFilename: String,
                                     inBundle bundle: Bundle = Bundle.main,
                                     decoder: JSONDecoder = JSONDecoder()) throws -> T {
        guard let jsonURL = bundle.url(forResource: jsonFilename,
                                       withExtension: "json") else {
            throw JSONDecodingError.fileNotFound(filename: jsonFilename, bundle: bundle)
        }

        return try [T].decode(jsonURL: jsonURL, decoder: decoder)
    }

}
