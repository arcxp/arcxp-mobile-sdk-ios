//  Copyright © 2021 The Washington Post. All rights reserved.

import Foundation

/// Implemented by classes that want to receive ``MediaEvent``s.
public protocol MediaEventSubscriber: AnyObject {

    /// Receive a ``MediaEvent`` on the main `DispatchQueue`.
    func receiveEvent(_ event: MediaEvent)

}
