//
//  ArcXPResizerTests.swift
//  ArcXP
//
//  Created by Mahesh Venkateswarlu on 11/16/22.
//  Copyright © 2022 Arc XP. All rights reserved.
//

import XCTest
@testable import ArcXP
// swiftlint: disable line_length
final class ArcXPResizerTests: BaseNetworkTests {

    private let deviceSize = UIScreen.main.bounds
    private let auth = ["1": "0b43282114a8bf3844aabd8c6fabe84289357a81d0dbc0897f5723a9e756e3fd"]

// MARK: V2 resizer tests

    func testv2ResizerUrlWithGreaterWidth() {
        let contentImgUrlString = "https://arcsales-arcsales-sandbox.web.arc-cdn.net/resizer/adLw87PrKaz0fKFm5zLVfRpB0rc=/arc-photo-arcsales/arc2-sandbox/public/JSV5BKVVVFBCDANIQFVHQ2NYHY.jpg"
        let contentImgWidth = 960
        let contentImgHeight = 1400
        let resizedUrl = ArcXPImageResizer.resizedImageUrl(originalImageSize: CGSize(width: contentImgWidth,
                                                                                       height: contentImgHeight),
                                                             originalUrl: contentImgUrlString,
                                                             auth: auth)
        let v2ExpectedResizedUrl = "https://arcsales-arcsales-sandbox.web.arc-cdn.net/resizer/v2/JSV5BKVVVFBCDANIQFVHQ2NYHY.jpg?auth=0b43282114a8bf3844aabd8c6fabe84289357a81d0dbc0897f5723a9e756e3fd&width=\(UIScreen.main.bounds.width)"
        XCTAssertEqual(v2ExpectedResizedUrl, resizedUrl)
    }

    func testv2ResizerUrlWithGreaterHeight() {
        let contentImgUrlString = "https://arcsales-arcsales-sandbox.web.arc-cdn.net/resizer/adLw87PrKaz0fKFm5zLVfRpB0rc=/arc-photo-arcsales/arc2-sandbox/public/JSV5BKVVVFBCDANIQFVHQ2NYHY.jpg"
        let contentImgWidth = 300
        let contentImgHeight = 1400
        let resizedUrl = ArcXPImageResizer.resizedImageUrl(originalImageSize: CGSize(width: contentImgWidth,
                                                                                       height: contentImgHeight),
                                                             originalUrl: contentImgUrlString,
                                                             auth: auth)
        let v2ExpectedResizedUrl = "https://arcsales-arcsales-sandbox.web.arc-cdn.net/resizer/v2/JSV5BKVVVFBCDANIQFVHQ2NYHY.jpg?auth=0b43282114a8bf3844aabd8c6fabe84289357a81d0dbc0897f5723a9e756e3fd&height=\(UIScreen.main.bounds.height)"
        XCTAssertEqual(v2ExpectedResizedUrl, resizedUrl)
    }

    func testv2ResizerUrlWithNilAuth() {
        let contentImgUrlString = "https://arcsales-arcsales-sandbox.web.arc-cdn.net/resizer/adLw87PrKaz0fKFm5zLVfRpB0rc=/arc-photo-arcsales/arc2-sandbox/public/JSV5BKVVVFBCDANIQFVHQ2NYHY.jpg"
        let contentImgWidth = 300
        let contentImgHeight = 1400
        let resizedUrl = ArcXPImageResizer.resizedImageUrl(originalImageSize: CGSize(width: contentImgWidth,
                                                                                       height: contentImgHeight),
                                                             originalUrl: contentImgUrlString,
                                                             auth: nil)
        XCTAssertEqual(contentImgUrlString, resizedUrl)
    }

    func testv2ResizerUrlWithGreaterHeightAndMultiAuthValues() {
        let contentImgUrlString = "https://arcsales-arcsales-sandbox.web.arc-cdn.net/resizer/adLw87PrKaz0fKFm5zLVfRpB0rc=/arc-photo-arcsales/arc2-sandbox/public/JSV5BKVVVFBCDANIQFVHQ2NYHY.jpg"
        let contentImgWidth = 300
        let contentImgHeight = 1400
        let auth = ["1": "0b43282114a8bf3844aabd8c6fabe84289357a81d0dbc0897f5723a9e756e3fd",
                    "2": "223113114a8bf3844aabd8c6fabe84289357a81d0dbc0897f5723a9e756e3fd"]
        let resizedUrl = ArcXPImageResizer.resizedImageUrl(originalImageSize: CGSize(width: contentImgWidth,
                                                                                       height: contentImgHeight),
                                                             originalUrl: contentImgUrlString,
                                                             auth: auth)
        let v2ExpectedResizedUrl = "https://arcsales-arcsales-sandbox.web.arc-cdn.net/resizer/v2/JSV5BKVVVFBCDANIQFVHQ2NYHY.jpg?auth=223113114a8bf3844aabd8c6fabe84289357a81d0dbc0897f5723a9e756e3fd&height=\(UIScreen.main.bounds.height)"
        XCTAssertEqual(v2ExpectedResizedUrl, resizedUrl)
    }

    func testv2ThumbnailUrl() {
        let contentImgUrlString = "https://arcsales-arcsales-sandbox.web.arc-cdn.net/resizer/adLw87PrKaz0fKFm5zLVfRpB0rc=/arc-photo-arcsales/arc2-sandbox/public/JSV5BKVVVFBCDANIQFVHQ2NYHY.jpg"
        let resizedUrl = ArcXPImageResizer.resizedThumbnailUrl(originalUrl: contentImgUrlString, auth: auth)
        let v2ExpectedResizedUrl = "https://arcsales-arcsales-sandbox.web.arc-cdn.net/resizer/v2/JSV5BKVVVFBCDANIQFVHQ2NYHY.jpg?auth=0b43282114a8bf3844aabd8c6fabe84289357a81d0dbc0897f5723a9e756e3fd&width=300.0"
        XCTAssertEqual(v2ExpectedResizedUrl, resizedUrl)
    }

    func testv2ResizerInvalidUrl() {
        let contentImgUrlString = "https://arcsales-arcsales-sandbox.web.arc-cdn.net/resizer/adLw87PrKaz0fKFm5zLVfRpB0rc=/arc-photo-arcsales/arc2-sandbox/public/JSV5BKVVVFBCDANIQFVHQ2NYHY"
        let contentImgWidth = 960
        let contentImgHeight = 1400
        let resizedUrl = ArcXPImageResizer.resizedImageUrl(originalImageSize: CGSize(width: contentImgWidth,
                                                                                       height: contentImgHeight),
                                                             originalUrl: contentImgUrlString,
                                                             auth: auth)
        XCTAssertEqual(resizedUrl, contentImgUrlString)
    }

}
// swiftlint: enable line_length
