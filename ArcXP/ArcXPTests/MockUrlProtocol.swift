//
//  MockUrlProtocol.swift
//  ArcXPContentTests
//
//  Created by Davis, Tyler on 1/24/22.
//  Copyright © 2022 The Washington Post Company. All rights reserved.
//

import Foundation
import XCTest

class MockURLProtocol: URLProtocol {
    
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, URL))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Received unexpected handler with no request set")
            return
        }
        do {
            let (response, localFileUrl) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: try Data(contentsOf: localFileUrl))
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
    }
}
