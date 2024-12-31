#import <UIKit/UIKit.h>

#import "PALDefines.h"

/**
 * Manages a nonce and its event reporting for a single content playback session.
 *
 * The below content playback session lifecycle methods must be accurately called in order to enable
 * programmatic monetization.
 */
PAL_EXTERN
NS_SWIFT_NAME(NonceManager)
@interface PALNonceManager : NSObject

/**
 * The nonce generated for this manager when it was loaded.
 *
 * This value will never change for a given <code>PALNonceManager</code> instance.
 * This nonce value is only valid for a single content playback session up to a maximum duration of
 * 6 hours.
 */
@property(nonnull, nonatomic, copy, readonly) NSString *nonce;

/**
 * A gesture recognizer that must be attached to each view each ad is displayed in during playback.
 *
 * Attach this gesture recognizer through <code>UIView</code>'s <code>addGestureRecognizer</code>:
 * method. Once the ad is complete, the gesture recognizer may be removed with
 * <code>removeGestureRecognizer</code>: and added to another one if the view is not the same.
 * This recognizer does not trigger any network requests.
 */
@property(nonnull, nonatomic, readonly) UIGestureRecognizer *gestureRecognizer;

/** Use <code>PALNonceLoader</code>'s <code>loadNonceManagerWithRequest</code>:
 * method to obtain an instance.
 * :nodoc:
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

/**
 * Notifies Google ad servers that a clickthrough on an ad has occurred during the given content
 * playback session.
 */
- (void)sendAdClick;

/**
 * Notifies Google ad servers that playback for the given content playback session has started. This
 * should be called on "video player start". This may be in response to a user-initiated action
 * (click-to-play) or an app initiated action (autoplay).
 *
 * This method will start asynchronous calls to Google servers to collect signals needed for IVT
 * monitoring and detection.
 */
- (void)sendPlaybackStart;

/**
 * Notifies Google ad servers that playback for the given content playback session has ended. This
 * should be called when playback ends (for example, when the player reaches end of stream, or when
 * the user exits playback mid-way, or when the user quits the app).
 *
 * This method ends the asynchronous calls to Google servers started in `sendPlaybackStart`.
 */
- (void)sendPlaybackEnd;

@end
