#import <Foundation/Foundation.h>

#import "PALDefines.h"

/** The PALSettings class stores SDK wide settings. */
PAL_EXTERN
NS_SWIFT_NAME(Settings)
@interface PALSettings : NSObject

/** Specify if storage is allowed (used for TCFv2 compliance). Default value is false. */
@property(nonatomic) BOOL allowStorage;

/**
 * Specify if the ad request is directed to a child or user of an unknown age (for example,
 * TFCD or TFUA). Default value is false.
 */
@property(nonatomic) BOOL directedForChildOrUnknownAge;

@end
