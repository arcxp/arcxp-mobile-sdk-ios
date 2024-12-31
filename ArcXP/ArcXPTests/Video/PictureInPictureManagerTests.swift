//
//  PictureInPictureManagerTests.swift
//  ArcXPTests
//
//  Created by David Seitz on 12/6/23.
//  Copyright © 2023 The Washington Post Company. All rights reserved.
//

import XCTest
import AVKit
@testable import ArcXP

class PictureInPictureManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    var customPlayer: AVPlayer!
    var viewController: UIViewController!
    
    // MARK: - Test Setup
    
    override func setUp() {
        super.setUp()
        customPlayer = AVPlayer()
        viewController = UIViewController()
    }
    
    override func tearDown() {
        super.tearDown()
        customPlayer = nil
        viewController = nil
    }
    
    // MARK: - Test Cases
    
    func testPictureInPictureNotSupported() {
        do {
            try PictureInPictureManager.setUp(with: customPlayer, for: viewController)
        } catch {
            XCTAssertEqual(error.localizedDescription, "Picture-in-picture operation failed due to picture-in-picture not being supported.")
        }
    }
    
    func testActivatePictureInPictureSession() {
        XCTAssertNoThrow(try PictureInPictureManager.activatePictureInPictureSession())
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .playback)
        XCTAssertEqual(AVAudioSession.sharedInstance().mode, .moviePlayback)
    }
    
    func testDeactivatePictureInPictureSession() {
        XCTAssertNoThrow(try PictureInPictureManager.deactivatePictureInPictureSession())
    }
    
    func testIsPictureInPictureSupported() {
        // Ensure that isPictureInPictureSupported() returns the correct value
        let supported = PictureInPictureManager.isPictureInPictureSupported()
        XCTAssertEqual(supported, AVPictureInPictureController.isPictureInPictureSupported())
    }
    
    func testPictureInPictureManualStart() {
        XCTAssertNoThrow(PictureInPictureManager.manuallyStartPictureInPicture())
    }
    
    func testPictureInPictureManaulStop() {
        XCTAssertNoThrow(PictureInPictureManager.manuallyStopPictureInPicture())
    }
    
    // MARK: - Errors
    
    func testLocalizedDescriptionForPictureInPictureNotSupported() {
        XCTAssertEqual(PictureInPictureManager.Error.pictureInPictureNotSupported.localizedDescription, "Picture-in-picture operation failed due to picture-in-picture not being supported.")
    }
}
