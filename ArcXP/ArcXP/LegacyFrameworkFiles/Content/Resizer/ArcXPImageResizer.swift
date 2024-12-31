//
//  ArcXPImageResizer.swift
//  ArcXP
//
//  Created by Mahesh Venkateswarlu on 11/16/22.
//  Copyright © 2022 Arc XP. All rights reserved.
//

import Foundation
import UIKit

/// Image resizer to resize the image based on the device size or the expected size.
public struct ArcXPImageResizer {

    private static var resizerPathUrl: String {
        return "/resizer/v2/"
    }

// MARK: V2 Resizer

    /// Resizes the original image url to the given size or device size based on the image size using v2 resizer logic.
    /// - Parameters:
    ///   - originalImageSize: `CGSize` of the originalImage from ANS content
    ///   - expectedImageSize: optional `CGSize` of expectedImage spec, if not given device size will be considered
    ///   - originalUrl: `String` of original cloudfront url
    ///   - auth: `[String:String]` dictionary that contains ["REVISION_TOKEN_VERSION":"VALUE"]. If contains multiple versions, the greatest ones will be considered.
    /// - Returns: v2 resized image url with the adjusted sizes
    public static func resizedImageUrl(originalImageSize: CGSize?,
                                       expectedImageSize: CGSize = CGSize(width: UIScreen.main.bounds.width,
                                                                          height: UIScreen.main.bounds.height),
                                       originalUrl: String?,
                                       auth: [String: String]?) -> String? {
        // Validations
        guard let imageAuth = auth,
              let authKey = imageAuth.keys.max(),
              let authToken = imageAuth[authKey],
              let fileName = fileNameInUrl(originalUrl),
              let originalImageSize = originalImageSize,
              isImageBiggerThanDevice(originalSize: originalImageSize, expectedSize: expectedImageSize) else {
            return originalUrl
        }

        var expectedImageWidth: CGFloat?
        var expectedImageHeight: CGFloat?
        // If image width is bigger than the expected size, get an image that fits the size
        if originalImageSize.width > expectedImageSize.width {
            expectedImageWidth = expectedImageSize.width
        } else if originalImageSize.height > expectedImageSize.height {
            expectedImageHeight = expectedImageSize.height
        }

        return constructResizerUrl(fileName: fileName,
                                   authToken: authToken,
                                   width: expectedImageWidth,
                                   height: expectedImageHeight)
    }

    /// Resizes the original image url to the thumbnail size 300.0 using v2 resizer logic.
    /// - Parameters:
    ///   - originalUrl: `String` of the original cloudfront url
    ///   - auth:`[String:String]` dictionary that contains ["REVISION_TOKEN_VERSION":"VALUE"] in ANS content. If contains multiple versions, the greatest ones will be considered.
    /// - Returns: v2 resized thumbnail size image url with the adjusted sizes
    public static func resizedThumbnailUrl(originalUrl: String?, auth: [String: String]?) -> String? {
        guard let imageAuth = auth,
              let authKey = imageAuth.keys.max(),
              let authToken = imageAuth[authKey],
              let fileName = fileNameInUrl(originalUrl) else {
            return originalUrl
        }
        return constructResizerUrl(fileName: fileName,
                                   authToken: authToken,
                                   width: 300.0)
    }

    /// Constructs the resizer url with the given parameters.
    /// - Parameters:
    ///  - fileName: `String` of the file name to resize
    ///  - authToken: `String` of the auth token to resize
    ///  - width: `CGFloat` of the width to resize
    ///  - height: `CGFloat` of the height to resize
    ///  - Returns: v2 resized image url with the adjusted sizes
    public static func constructResizerUrl(fileName: String, authToken: String, width: CGFloat? = nil, height: CGFloat? = nil) -> String {
        // Construct resizer url
        let authTokenQueryParam = "?auth=" + authToken
        var v2ResizedUrlRelativePath = resizerPathUrl + fileName + authTokenQueryParam
        if let width = width {
            v2ResizedUrlRelativePath += "&width=\(width)"
        }
        if let height = height {
            v2ResizedUrlRelativePath += "&height=\(height)"
        }
        return ArcXPContentManager.client.configuration.hostDomain + v2ResizedUrlRelativePath
    }

    private static func fileNameInUrl(_ cloudfrontUrl: String?) -> String? {
        guard let urlComponents = cloudfrontUrl?.components(separatedBy: "/"),
              let fileName = urlComponents.last,
              fileName.components(separatedBy: ".").count == 2 else {
            LoggingManager.log("Cloudfront url is file name in  \(String(describing: cloudfrontUrl))", level: .error)
            return nil
        }
        return fileName
    }

    private static func isImageBiggerThanDevice(originalSize: CGSize,
                                                expectedSize: CGSize = CGSize(width: UIScreen.main.bounds.width,
                                                                              height: UIScreen.main.bounds.height)) -> Bool {
        return (originalSize.width > expectedSize.width || originalSize.height > expectedSize.height)
    }
}
