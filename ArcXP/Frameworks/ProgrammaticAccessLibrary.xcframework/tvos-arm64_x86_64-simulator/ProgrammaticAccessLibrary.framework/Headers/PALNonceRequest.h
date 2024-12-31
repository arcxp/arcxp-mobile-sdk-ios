#import <Foundation/Foundation.h>

#import "PALDefines.h"

/** A nullable flag used for various <code>PALNonceRequest</code> fields. */
typedef NS_ENUM(NSInteger, PALFlag) {
  /** Indicates that the flag value is unknown or not provided. */
  PALFlagNull = 0,
  /** Indicates that the flag value is set to on, or true. */
  PALFlagOn,
  /** Indicates that the flag value is set to off, or false. */
  PALFlagOff,
} NS_SWIFT_NAME(Flag);

/**
 * The <code>PALNonceRequest</code> class contains data needed to create a
 * programmatic access nonce.
 *
 * A <code>PALNonceRequest</code> instance is passed into a <code>PALNonceLoader</code>'s
 * <code>loadNonceManagerWithRequest</code>: method to load a new <code>PALNonceManager</code>,
 * containing the result nonce.
 */
PAL_EXTERN
NS_SWIFT_NAME(NonceRequest)
@interface PALNonceRequest : NSObject

/**
 * Whether the player intends to continuously play the content videos one after another similar to
 * a TV broadcast or video playlist. <code>PALFlagNull</code> by default.
 */
@property(nonatomic, getter=isContinuousPlayback) PALFlag continuousPlayback;

/**
 * The description URL of the video being played. Any description URL string longer than 500
 * characters will be ignored and excluded from the nonce.
 */
@property(nullable, nonatomic, copy) NSURL *descriptionURL;

/** Whether VAST icons are supported by the video player. @c NO by default. */
@property(nonatomic, getter=isIconsSupported) BOOL iconsSupported;

/**
 * The name of the OMID Integration Partner. Any partner name string longer than 200 characters
 * will be ignored and excluded from the nonce.
 *
 * This must match the name supplied to the OM SDK for the ad session. For further details, see the
 * <a href="https://iabtechlab.com/omsdk/docs/onboarding"> OM SDK Onboarding Guide</a>.
 *
 * To successfully include the <code>omid_p=</code> value in a nonce, both this
 * <code>OMIDPartnerName</code> and <code>OMIDPartnerVersion</code> must be set.
 */
@property(nullable, nonatomic, copy) NSString *OMIDPartnerName __TVOS_UNAVAILABLE;

/**
 * The OMID Integration Partner's version string. Any partner version string longer than 200
 * characters will be ignored and excluded from the nonce.
 *
 * This must match the string supplied to the OM SDK for the ad session.
 *
 * To successfully include the <code>omid_p=</code> value in a nonce, both this
 * <code>OMIDPartnerVersion</code> and <code>OMIDPartnerName</code> must be set.
 */
@property(nullable, nonatomic, copy) NSString *OMIDPartnerVersion __TVOS_UNAVAILABLE;

/**
 * The version of OMID supported by the ad player. Any OMID version string longer than 200
 * characters will be ignored and excluded from the nonce.
 *
 * This must be set to the version provided by the OM SDK's [OMIDSDK versionString] method. For
 * further details, see the <a href="https://iabtechlab.com/omsdk/docs/api/1.2">OMID API docs</a>.
 */
@property(nullable, nonatomic, copy) NSString *OMIDVersion __TVOS_UNAVAILABLE;

/**
 * The maximum allowed length for the generated nonce. By default there is no limit.
 * Choosing a shorter nonce length limit may cause various targeting properties to
 * be excluded from the nonce.
 */
@property(nonatomic) NSUInteger nonceLengthLimit;

/**
 * The name of the partner player being used to play the ad. Any player type string longer than
 * 200 characters will be ignored and excluded from the nonce.
 */
@property(nullable, nonatomic, copy) NSString *playerType;

/**
 * The version of the partner player being used to play the ad. Any player version string longer
 * than 200 characters will be ignored and excluded from the nonce.
 */
@property(nullable, nonatomic, copy) NSString *playerVersion;

/**
 * The publisher provided ID. Any PPID longer than 200 characters will be ignored and excluded
 * from the nonce.
 */
@property(nullable, nonatomic, copy) NSString *PPID;

/**
 * The session ID is a temporary random ID. It is used exclusively for
 * frequency capping. A session ID must be a UUID.
 */
@property(nullable, nonatomic, copy) NSString *sessionID;

/**
 * A set of integers representing a player's supported frameworks. These values
 * are defined in the AdCOM 1.0 "API Frameworks" list:
 * https://github.com/InteractiveAdvertisingBureau/AdCOM/blob/master/AdCOM%20v1.0%20FINAL.md#list--api-frameworks-.
 * Example: "2,7,9" indicates supports for VPAID 2.0, OMID 1.0, and SIMID 1.1.
 */
@property(nullable, nonatomic) NSMutableSet<NSNumber *> *supportedAPIFrameworks;

/** An optional reference to pass through to identify requests upon completion.  */
@property(nullable, nonatomic, copy) id userInfo;

/**
 * The height of the video player, in pixels. Not included in the nonce by default.
 *
 * This must be a positive integer to represent a valid ad size in pixels, not points. See
 * <a href="https://support.google.com/admanager/answer/1068325">Google Ad Manager
 * documentation</a> for details.
 */
@property(nonatomic) NSUInteger videoPlayerHeight;

/**
 * The width of the video player, in pixels. Not included in the nonce by default.
 *
 * This must be a positive integer to represent a valid ad size in pixels, not points. See
 * <a href="https://support.google.com/admanager/answer/1068325">Google Ad Manager
 * documentation</a> for details.
 */
@property(nonatomic) NSUInteger videoPlayerWidth;

/** Whether the ad will be played automatically. <code>PALFlagNull</code> by default. */
@property(nonatomic) PALFlag willAdAutoPlay;

/** Whether the ad will be play while muted. <code>PALFlagNull</code> by default. */
@property(nonatomic) PALFlag willAdPlayMuted;

@end
