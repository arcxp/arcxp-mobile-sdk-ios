#import <Foundation/Foundation.h>

#import "PALDefines.h"

@class PALNonceLoader;
@class PALNonceManager;
@class PALNonceRequest;
@class PALSettings;

/** Delegate object used to receive updates from <code>PALNonceLoader</code>. */
NS_SWIFT_NAME(NonceLoaderDelegate)
@protocol PALNonceLoaderDelegate <NSObject>

/**
 * Called when a <code>PALNonceManager</code> is successfully loaded.
 *
 * @param nonceLoader The PALNonceLoader from which loading was requested.
 * @param request The PALNonceRequest used to request the nonce manager.
 * @param nonceManager A new PALNonceManager that contains a nonce for a single content stream.
 */
- (void)nonceLoader:(nonnull PALNonceLoader *)nonceLoader
            withRequest:(nonnull PALNonceRequest *)request
    didLoadNonceManager:(nonnull PALNonceManager *)nonceManager;

/**
 * Called when there was an error loading the <code>PALNonceManager</code>, or if loading timed out.
 *
 * @param nonceLoader The @c PALNonceLoader from which loading was requested.
 * @param request The @c PALNonceRequest used to request the nonce manager.
 * @param error An error describing the failure.
 */
- (void)nonceLoader:(nonnull PALNonceLoader *)nonceLoader
         withRequest:(nonnull PALNonceRequest *)request
    didFailWithError:(nonnull NSError *)error NS_SWIFT_NAME(nonceLoader(_:with:didFailWith:));

@end

/**
 * Allows publishers to create a <code>PALNonceManager</code> for a single content stream.
 *
 * This instance's methods and properties are not thread safe. Usage:
 * 1. Create a new <code>PALNonceLoader</code>.
 * 2. Create a new <code>PALNonceRequest</code> and populate its properties.
 * 3. Call <code>loadNonceManagerWithRequest</code>: to get a new <code>PALNonceManager</code>,
 * which will contain the nonce to use for ad requests for a single content stream.
 * 4. For subsequent content streams, create a new <code>PALNonceRequest</code> but reuse the same
 *    <code>PALNonceLoader</code>.
 */
PAL_EXTERN
NS_SWIFT_NAME(NonceLoader)
@interface PALNonceLoader : NSObject

/** Initializes the nonce loader with default settings. */
- (nonnull instancetype)init;

/**
 * Initializes the nonce loader
 * @param settings The settings used by this loader.
 */
- (nonnull instancetype)initWithSettings:(nonnull PALSettings *)settings;

/** The version of this SDK in major.minor.patch format, or "(null)" when unavailable. */
@property(nonnull, nonatomic, readonly) NSString *SDKVersion;

/** The object receiving <code>PALNonceLoaderDelegate</code> callbacks for this instance. */
@property(nullable, nonatomic, weak) id<PALNonceLoaderDelegate> delegate;

/**
 * Asynchronously loads a <code>PALNonceManager</code> using the information in
 * the given request, informing the delegate of success or failure.
 *
 * Multiple concurrent requests are supported.
 *
 * @param request The request containing information about the context in which the nonce will be
 *     used.
 */
- (void)loadNonceManagerWithRequest:(nonnull PALNonceRequest *)request;

@end
