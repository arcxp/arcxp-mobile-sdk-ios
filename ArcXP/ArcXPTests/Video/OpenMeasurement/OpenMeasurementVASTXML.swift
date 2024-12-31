//  Copyright © 2021 The Washington Post. All rights reserved.

/* *****************************************************************
 iOS-only, until IAB adds support for tvOS!
 */

@testable import ArcXP

import Foundation
import OMSDK_Washpost

// A simple DOM representation of a VAST XML file. The `rootElement` points to
// the root of the DOM.
class OpenMeasurementVASTXML: NSObject {

    /// A generic XML DOM element. Its children can be accessed via the
    /// `children` array, or by a subscript of the child's name, e.g.
    /// `element["ChildNode"]?.first`.
    ///
    /// - note: This is a class, not a struct, so that it can be referenced
    ///   weakly by its child elements.
    class XMLElement: NSObject {

        /// The element's inline attributes.
        var attributes = [String: String]()

        /// The `CDATA ` block, if any.
        var cdata: Data?

        /// A UTF-8 String representation of the `cdata`. If `cdata` is `nil`,
        /// or it can't be parsed into a UTF-8 string, then this will be `nil`.
        var cdataString: String? {
            if let cdata = cdata {
                return String(data: cdata, encoding: .utf8)
            } else {
                return nil
            }
        }

        /// The text of the element, if any.
        var characters: String?

        /// The child elements, in the order they appear in the XML.
        var children = [XMLElement]()

        /// The name (i.e. type) of the element.
        var name: String

        /// The parent element. This will be `nil` only if the element is the
        /// root element of the DOM.
        weak var parent: XMLElement?

        // MARK: - Initialization

        /// Construct the XML element.
        init(name: String,
             parent: XMLElement?,
             attributes: [String: String] = [:]) {
            self.name = name
            self.parent = parent
            self.attributes = attributes
        }

        // MARK: - Functions

        /// Get all child elements with a specific name.
        ///
        /// - parameter childName: The name (i.e. type) of the XML element.
        subscript(childName: String) -> [XMLElement]? {
            return children.filter { (child) -> Bool in
                child.name == childName
            }
        }

        /// Print the DOM as an XML-style format. (It won't necessarily be
        /// *valid* XML, so it's just for debugging purposes.)
        func toString(indentLevel: Int = 0) -> String {
            var output = ""
            let indent = Array(repeating: " ", count: indentLevel * 2).joined()
            output.append("\(indent)<\(name)")

            if !attributes.isEmpty {
                let attributeString = attributes.reduce("") { (string, tuple) in
                    return string.appending(" \(tuple.key)=\"\(tuple.value)\"")
                }
                output.append(attributeString)
            }

            if cdata == nil && characters == nil && children.isEmpty {
                output.append("/>")
            } else {
                output.append(">")

                if let characters = characters {
                    output.append("\(indent)  \(characters)")
                }

                if let cdata = cdata,
                   let cdataString = String(data: cdata, encoding: .utf8) {
                    output.append("\(indent)  <![CDATA[:\(cdataString)]]>")
                }

                for child in children {
                    output.append(child.toString(indentLevel: indentLevel + 1))
                }

                output.append("\(indent)</\(name)>")
            }

            return output
        }
    }

    // MARK: - Public Properties

    /// The root element of the DOM.
    var rootElement: XMLElement?

    /// The list of `OMIDWashpostVerificationScriptResource`s that are
    /// generated from the `Ad/InLine/AdVerifications/Verification` XML
    /// elements. They're constructed using the three-argument initializer, so
    /// if any of the arguments is `nil` or malformed, then no resource will be
    /// returned and a message will be logged.
    var verificationScriptResources: [OMIDWashpostVerificationScriptResource] {
        let resources = adVerifications?
            .compactMap { (verification) -> OMIDWashpostVerificationScriptResource? in
                if let vendor = verification.attributes["vendor"],
                   let cdataString = verification["JavaScriptResource"]?.first?.cdataString,
                   let url = URL(string: cdataString),
                   let parameters = verification["VerificationParameters"]?.first?.cdataString,
                   let resource = OMIDWashpostVerificationScriptResource(url: url,
                                                                         vendorKey: vendor,
                                                                         parameters: parameters) {
                    return resource
                } else {
                    return nil
                }
            }

        return resources ?? []
    }

    // MARK: - Internal Properties

    private var adVerifications: [XMLElement]? {
        return rootElement?["Ad"]?.first?["InLine"]?.first?["AdVerifications"]?.first?["Verification"]
    }

    /// The XML element that new elements will be added to. When the
    /// `currentElement` is finished being parsed, the `currentElement` is
    /// reset to its parent.
    private var currentElement: XMLElement?

    // MARK: - Initialization

    /// Construct the XML from a VAST XML URL. By the time initialization is
    /// finished, the `rootElement` will point to the full XML DOM.
    init(vastUrl: URL) {
        super.init()

        let parser = XMLParser(contentsOf: vastUrl)
        parser?.delegate = self
        parser?.parse()
    }

    init?(xmlString: String) {
        super.init()

        guard let data = xmlString.data(using: .utf8) else {
            return nil
        }

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }

}

extension OpenMeasurementVASTXML: XMLParserDelegate {

    /// Handle the start of an XML element.
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        let newElement = XMLElement(name: elementName,
                                    parent: currentElement,
                                    attributes: attributeDict)

        if rootElement == nil {
            rootElement = newElement
        } else {
            currentElement?.children.append(newElement)
        }

        currentElement = newElement
    }

    /// Handle the end of an XML element.
    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        currentElement = currentElement?.parent
    }

    /// Handle unformatted XML data by assigning it to the current element's
    /// `cdata` property.
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        currentElement?.cdata = CDATABlock
    }

    /// Handle text in an XML element by trimming it and assigning it to the
    /// current element's `characters` property.
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedString.isEmpty {
            currentElement?.characters = trimmedString
        }
    }

}

extension OpenMeasurementAdSession {

    /// Construct the session from a VAST XML document. The XML's
    /// `<AdVerification>` tag is parsed to create an array of
    /// `OMIDWashpostVerificationScriptResource`s, and these are passed to the
    /// other designated initializer.
    ///
    /// - parameter vastXML: The XML document with OpenMeasurement ad tracking
    ///   information. The only part of the XML that's used is the
    ///   `<AdVerification>` element, which is used to create an array of
    ///   `OMIDWashpostVerificationScriptResource`s.
    /// - parameter contentUrl: The URL of the article or document that
    ///   contains the ad-enabled video. It may be `nil`.
    /// - parameter playerView: The `UIView` that plays the video. If it
    ///   contains any subviews that aren't part of the video itself (such as
    ///   playback controls, information labels, etc.), these must also be
    ///   registered as friendly obstructions. Failure to do so will impact the
    ///   ad's monetization, because the ad provider (and OpenMeasurement) will
    ///   consider the ad content to be partially blocked by something else.
    convenience init(vastXML: OpenMeasurementVASTXML,
                     contentUrl: URL?,
                     playerView: UIView?) throws {
        // https://interactiveadvertisingbureau.github.io/Open-Measurement-SDKiOS/#2-prepare-the-measurement-resources-
        let resources = vastXML.verificationScriptResources
        try self.init(vastVerificationScriptResources: resources,
                      contentUrl: contentUrl,
                      playerView: playerView)
    }

}
