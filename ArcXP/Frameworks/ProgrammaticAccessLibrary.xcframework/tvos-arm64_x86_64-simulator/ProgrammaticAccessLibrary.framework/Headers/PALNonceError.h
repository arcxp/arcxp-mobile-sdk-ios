#import <Foundation/Foundation.h>

#import "PALDefines.h"

/** ProgammaticAccessLibrary errors. */
PAL_EXTERN
NS_SWIFT_NAME(NonceErrorDomain)
NSErrorDomain const PALNonceErrorDomain;

/** Error codes in <code>PALNonceErrorDomain</code>. */
typedef NS_ERROR_ENUM(PALNonceErrorDomain, PALNonceErrorCode){
    /** An unknown error occurred. */
    PALNonceErrorCodeUnknown = 100,

    /** Resource fetching related error codes. */

    /** Received an invalid response while fetching resources. */
    PALNonceErrorCodeFetchBadResponse = 200,
    /** Could not obtain a response while fetching resources. */
    PALNonceErrorCodeFetchNoResponse = 201,
    /** Timed out waiting for a response while fetching resources. */
    PALNonceErrorCodeFetchTimedOut = 202,

    /** Nonce creation related error codes. */

    /** Could not initialize encoding while creating a nonce. */
    PALNonceErrorCodeEncoderInitFailed = 300,
    /** Could not encode while creating a nonce. */
    PALNonceErrorCodeEncodingFailed = 301,
    /** The generated nonce was too long. */
    PALNonceErrorCodeTooLong = 302,
    /** The OS version is too old and not supported. */
    PALNonceErrorCodeOSVersionTooOld = 303,

} NS_SWIFT_NAME(NonceError);
