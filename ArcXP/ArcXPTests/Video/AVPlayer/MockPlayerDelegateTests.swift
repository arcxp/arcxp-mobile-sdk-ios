//  Copyright © 2021 The Washington Post. All rights reserved.

import AVFoundation
import XCTest

/// What, a test for a class that's only in the test target? Yes.
class MockPlayerDelegateTests: XCTestCase {

    func testEqualExpectedAndActualCallsOk() {
        let delegate = MockPlayerDelegate()
        delegate.calls = [
            .playerMuted,
            .playerUnmuted,
            .playerPaused,
            .playerStarted,
            .playerPlayed25Percent,
            .playerPlayed50Percent,
            .playerPlayed75Percent,
            .playerCompleted
        ]
        XCTAssertTrue(delegate.wereExpectedCallsMade(delegate.calls))
    }

    func testSameNumberOfActualAndExpectedCallsFailsIfOutOfOrder() {
        let delegate = MockPlayerDelegate()
        delegate.calls = [
            .playerMuted,
            .playerPlayed25Percent,
            .playerUnmuted,
            .playerPaused,
            .playerStarted,
            .playerPlayed75Percent,
            .playerCompleted,
            .playerPlayed50Percent
        ]
        let expectedCalls: [MockPlayerDelegate.Call] = [
            .playerMuted,
            .playerUnmuted,
            .playerPaused,
            .playerStarted,
            .playerPlayed25Percent,
            .playerPlayed50Percent,
            .playerPlayed75Percent,
            .playerCompleted
        ]
        XCTAssertFalse(delegate.wereExpectedCallsMade(expectedCalls))
    }

    func testFewerActualThanExpectedCallsFails() {
        let delegate = MockPlayerDelegate()
        delegate.calls = [
            .playerMuted,
            .playerUnmuted,
            .playerPaused,
            .playerStarted,
            .playerPlayed25Percent
        ]
        let expectedCalls: [MockPlayerDelegate.Call] = [
            .playerMuted,
            .playerUnmuted,
            .playerPaused,
            .playerStarted,
            .playerPlayed25Percent,
            .playerPlayed50Percent,
            .playerPlayed75Percent,
            .playerCompleted
        ]
        XCTAssertFalse(delegate.wereExpectedCallsMade(expectedCalls))
    }

    func testMoreActualCallsThanExpectedOkIfAllExpectedCallsAreMadeInOrder() {
        let delegate = MockPlayerDelegate()
        delegate.calls = [
            .playerMuted,
            .playerUnmuted,
            .playerPaused,
            .playerStarted,
            .playerWaiting,
            .playerResumed,
            .playerPlayed25Percent,
            .playerPlayed50Percent,
            .playerPlayed75Percent,
            .playerWaiting,
            .playerResumed,
            .playerCompleted
        ]
        let expectedCalls: [MockPlayerDelegate.Call] = [
            .playerMuted,
            .playerUnmuted,
            .playerPaused,
            .playerStarted,
            .playerPlayed25Percent,
            .playerPlayed50Percent,
            .playerPlayed75Percent,
            .playerCompleted
        ]
        XCTAssertTrue(delegate.wereExpectedCallsMade(expectedCalls))
    }

    func testMoreActualCallsThanExpectedFailsIfExpectedCallsAreMadeOutOfOrder() {
        let delegate = MockPlayerDelegate()
        delegate.calls = [
            .playerMuted,
            .playerPlayed25Percent,
            .playerPlayed50Percent,
            .playerPlayed75Percent,
            .playerUnmuted,
            .playerPaused,
            .playerStarted,
            .playerWaiting,
            .playerResumed,
            .playerWaiting,
            .playerResumed,
            .playerCompleted
        ]
        let expectedCalls: [MockPlayerDelegate.Call] = [
            .playerMuted,
            .playerUnmuted,
            .playerPlayed25Percent,
            .playerPlayed50Percent,
            .playerPlayed75Percent,
            .playerCompleted,
            .playerPaused,
            .playerStarted
        ]
        XCTAssertFalse(delegate.wereExpectedCallsMade(expectedCalls))
    }

}
