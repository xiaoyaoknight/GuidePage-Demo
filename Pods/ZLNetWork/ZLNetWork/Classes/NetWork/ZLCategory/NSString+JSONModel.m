//
//  NSString+JSONModel.m
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import "NSString+JSONModel.h"

@implementation NSString (JSONModel)

#if __LP64__ || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
#else
- (NSInteger)longValue {
    return [self integerValue];
}

- (BOOL)charValue {
    return [self boolValue];
}
#endif

@end
