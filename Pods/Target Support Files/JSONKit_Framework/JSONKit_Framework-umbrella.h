#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "JSONKit.h"
#import "JSONKit_Framework.h"

FOUNDATION_EXPORT double JSONKit_FrameworkVersionNumber;
FOUNDATION_EXPORT const unsigned char JSONKit_FrameworkVersionString[];

