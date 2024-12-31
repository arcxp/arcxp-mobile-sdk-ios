// //  Copyright © 2021 The Washington Post. All rights reserved.
//
// @testable import ArcXP
// import OMSDK_Washpost
//
// import AVFoundation
// import XCTest
//
// class OpenMeasurementAdSessionTests: ArcMediaTestBase {
//
//     static var vastXML: OpenMeasurementVASTXML!
//     static var oldLogLevel: ArcXPLogger.Level!
//
//     class override func setUp() {
//         super.setUp()
//         let url = Bundle(for: Self.self).url(forResource: "vast-sample", withExtension: "xml")!
//         vastXML = OpenMeasurementVASTXML(vastUrl: url)
//         testInitializionWithoutActivatingOMIDSDKThrows()
//         OMIDWashpostSDK.shared.activate()
//
//         oldLogLevel = ArcXPLogger.level
//         ArcXPLogger.level = .all
//     }
//
//     override class func tearDown() {
//         super.tearDown()
//         ArcXPLogger.level = oldLogLevel
//     }
//
//     /// Confirm that the expected error is thrown when the session is started
//     /// before the `OMIDWashpostSDK.shared` session is activated. There's no
//     /// way do *de* activate a session, though, so this is done once, by
//     /// calling it from the static `setUp()` function.
//     static func testInitializionWithoutActivatingOMIDSDKThrows() {
//         do {
//             _ = try OpenMeasurementAdSession(vastXML: vastXML,
//                                              contentUrl: nil,
//                                              playerView: nil)
//             XCTFail("Should have thrown an error because the OMID session hasn't started")
//         } catch {
//             XCTAssertEqual((error as NSError).code, 2)
//             XCTAssertEqual((error as NSError).domain, "com.omid.library")
//         }
//     }
//
//     func testInitializionAfterSessionOk() throws {
//         let session = try OpenMeasurementAdSession(vastXML: Self.vastXML,
//                                                    contentUrl: nil,
//                                                    playerView: nil)
//         let config = session.configuration
//         XCTAssertEqual(config.creativeType, .video)
//         XCTAssertEqual(config.impressionType, .beginToRender)
//         XCTAssertEqual(config.impressionOwner, .nativeOwner)
//         XCTAssertEqual(config.mediaEventsOwner, .nativeOwner)
//         XCTAssertEqual(config.isolateVerificationScripts, false)
//     }
//
//     func testSampleVideoFiresMediaEvents() throws {
//         let video = AVPlayerItem(url: fifteenSecondVideoUrl)
//         let player = AVPlayer(playerItem: video)
//         let session = OpenMeasurementAdSession.debugSession(for: nil)
//
//         let observer = PlayerObserver(player: player)
//         print(observer) // dummy statement to prevent Xcode from warning about
//                         // an unused property. If I initialize it like
//                         // `_ = PlayerObserver(player: player)`, it will go out
//                         // of scope immediately and won't set up the proper
//                         // observations.
//
//         // Set up the event expectations
//         var expectations = [XCTestExpectation]()
//
//         let startedExpectation = expectation(description: "Ad started")
//         expectations.append(startedExpectation)
//         player.fire(at: 0.5) {
//             session?.receiveEvent(.playerAdStarted(player, adInfo: nil))
//             startedExpectation.fulfill()
//         }
//
//         let muteExpectation = expectation(description: "Player muted")
//         expectations.append(muteExpectation)
//         player.fire(at: 1.0) {
//             player.isMuted = true
//             session?.receiveEvent(.playerAdMuted(player, adInfo: nil))
//             muteExpectation.fulfill()
//         }
//
//         let unmuteExpectation = expectation(description: "Player unmuted")
//         expectations.append(unmuteExpectation)
//         player.fire(at: 2.0) {
//             player.isMuted = false
//             session?.receiveEvent(.playerAdUnmuted(player, adInfo: nil))
//             unmuteExpectation.fulfill()
//         }
//
//         let firstQuartileExpectation = expectation(description: "Played 25%")
//         expectations.append(firstQuartileExpectation)
//         player.fire(at: 15.0 / 4.0) {
//             session?.receiveEvent(.playerAdPlayed25Percent(player, adInfo: nil))
//             firstQuartileExpectation.fulfill()
//         }
//
//         let midpointExpectation = expectation(description: "Played 50%")
//         expectations.append(midpointExpectation)
//         player.fire(at: 15.0 / 2.0) {
//             session?.receiveEvent(.playerAdPlayed50Percent(player, adInfo: nil))
//             midpointExpectation.fulfill()
//         }
//
//         let thirdQuartileExpectation = expectation(description: "Played 75%")
//         expectations.append(thirdQuartileExpectation)
//         player.fire(at: 15.0 * 0.75) {
//             session?.receiveEvent(.playerAdPlayed75Percent(player, adInfo: nil))
//             thirdQuartileExpectation.fulfill()
//         }
//
//         let pauseExpectation = expectation(description: "Player Ad paused")
//         expectations.append(pauseExpectation)
//         player.fire(at: 15.0 * 0.85) {
//             player.pause()
//             session?.receiveEvent(.playerAdPaused(player, adInfo: nil))
//             player.play()
//             session?.receiveEvent(.playerAdPlaying(player, adInfo: nil))
//             pauseExpectation.fulfill()
//         }
//
//         let completedExpectation = expectation(description: "Player Ad resumed")
//         expectations.append(completedExpectation)
//         player.fire(at: 15.0) {
//             player.play()
//             session?.receiveEvent(.playerAdCompleted(player, adInfo: nil))
//             completedExpectation.fulfill()
//         }
//
//         player.play()
//
//         wait(for: expectations, timeout: 18.0, enforceOrder: true)
//         observer.stop()
//     }
//
//     #if os(iOS)
//     func testFriendlyObstructions() {
//         let viewController = ArcMediaPlayerViewController.loadFromStoryboard()
//         let playerView = viewController.playerView
//         let obstructions = playerView.friendlyAdObstructions
//         XCTAssertFalse(obstructions.isEmpty)
//
//         _ = OpenMeasurementAdSession.debugSession(for: playerView)
//     }
//     #endif
//
// }
