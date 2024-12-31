//  Copyright © 2021 The Washington Post. All rights reserved.

@testable import ArcXP
import XCTest

class OpenMeasurementVASTResponseTests: ArcMediaTestBase {

    func testParseSampleXml() throws {
        let url = testBundle.url(forResource: "vast-sample", withExtension: "xml")!
        let xml = OpenMeasurementVASTXML(vastUrl: url)

        XCTAssertEqual(xml.rootElement?.name, "VAST")
        XCTAssertNotNil(xml.rootElement?["Ad"]?[0]["InLine"]?[0])
    }

    func testExpectedVerificationParameters() throws {
        let url = testBundle.url(forResource: "vast-sample", withExtension: "xml")!
        let xml = OpenMeasurementVASTXML(vastUrl: url)
        let verificationScriptResources = xml.verificationScriptResources
        XCTAssertEqual(verificationScriptResources.count, 2)

        let firstResource = verificationScriptResources[0]
        XCTAssertEqual(firstResource.vendorKey, "imasdk.googleapis.com-test")
    }

    func testToStringProducesValidXml() {
        let url = testBundle.url(forResource: "vast-sample", withExtension: "xml")!
        let originalXml = OpenMeasurementVASTXML(vastUrl: url)
        let xmlString = originalXml.rootElement!.toString()
        print("Original XML: \(xmlString)")

        let newXml = OpenMeasurementVASTXML(xmlString: xmlString)!
        print("New XML: \(newXml.rootElement!.toString())")

        // They can't be tested for equality, because the XMLElements
        // will have different, randomly-generated IDs.
    }

}
