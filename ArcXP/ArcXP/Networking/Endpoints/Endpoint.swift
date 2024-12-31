//
//  NetworkDestination.swift
//  Commerce
//
//  Created by Seitz, David on 7/2/20.
//  Copyright © 2020 The Washington Post Company. All rights reserved.
//

/// A dummy class that's passed to ``Bundle(for:)``. If any other parts of the
/// Commerce framework need to use the resource bundle, then this should be
/// factored out so that everyone can use it.
class BundleTarget: NSObject {

}

import Foundation

/// A description of network request details, including path, headers, parameters, and others.
protocol Endpoint {

    /// The base URL for the endpoint.
    var baseUrl: String { get }

    /// The specific resource to access.
    var path: String { get }

    /// Query strings for the given ``baseUrl``.
    var urlParameters: [String: String]? { get }

    /// Construct a URL containing information from the ``baseUrl``, `endpoint`, and ``urlParameters``.
    /// - returns: A fully constructed ``URL`` object containing all relevant URL information.
    var url: URL? { get }

    /// The HTTP method required by this endpoint.
    var method: String { get }

    /// Headers to be included with this network request.
    var headers: [String: String]? { get }

    /// Body data to be included with this network request.
    var body: Data? { get }
}

extension Endpoint {

    var url: URL? {
        var urlString: String

        if Subscriptions.mock.mockNetworkResponseEnabled {
            // Use the JSON file in the framework's resource bundle (i.e.
            // ArcXPCommerceResources.bundle).
            urlString = ""
            if let resourceUrl = Bundle(for: BundleTarget.self).resourceURL {
                var mockBaseUrl = resourceUrl.absoluteString
                if mockBaseUrl.hasSuffix("/") {
                    _ = mockBaseUrl.dropLast() // remove the trailing slash
                }

                let folderPath = "SubscriptionsMocks/\(Subscriptions.mock.version.rawValue)/\(Subscriptions.mock.result.rawValue)"
                mockBaseUrl.append(folderPath)
                urlString = mockBaseUrl + path
                urlString.append(".json")
            }
        } else  if ArcXPContentManager.client.mock.useMocks {
            // Use the JSON file in the Mocks folder for tests
            urlString = ""
            if let resourceUrl = Bundle(for: BundleTarget.self).resourceURL {
                var mockBaseUrl = resourceUrl.absoluteString
                if mockBaseUrl.hasSuffix("/") {
                    _ = mockBaseUrl.dropLast() // remove the trailing slash
                }
                let folderPath = ArcXPContentManager.client.mock.mockType == .success ? "ContentMocks/success" : "ContentMocks/failure"
                mockBaseUrl.append(folderPath)
                urlString = mockBaseUrl + path
                if let urlParameters = urlParameters {
                    // sort the dictionary by key to ensure the mock file formats
                    for parameter in urlParameters.sorted(by: {$0.0 < $1.0}) {
                        urlString.append(parameter.key + parameter.value)
                    }
                }
                // For the failure response, it isn't json at the moment
                if ArcXPContentManager.client.mock.mockType == .success {
                    urlString.append(".json")
                }
            }
        } else {
            urlString = baseUrl + path

            if let urlParameters = urlParameters {
                for parameter in urlParameters {
                    urlString.append("\(urlString.contains("?") ? "&" : "?")\(parameter.key)=\(parameter.value)")
                }
            }
        }

        return URL(string: urlString)
    }
}
