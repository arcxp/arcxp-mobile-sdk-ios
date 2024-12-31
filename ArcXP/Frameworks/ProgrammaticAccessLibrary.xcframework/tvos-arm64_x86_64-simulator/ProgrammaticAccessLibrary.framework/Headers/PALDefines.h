#import <Foundation/Foundation.h>

#if defined(__cplusplus)
#define PAL_EXTERN extern "C" __attribute__((visibility("default")))
#else
#define PAL_EXTERN extern __attribute__((visibility("default")))
#endif  // defined(__cplusplus)
