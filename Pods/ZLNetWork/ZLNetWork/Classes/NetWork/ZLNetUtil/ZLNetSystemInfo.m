//
//  ZLNetSystemInfo.m
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import "ZLNetSystemInfo.h"
#import "ZLNetKeychainWrapper.h"
#import <UIKit/UIKit.h>

@implementation ZLNetSystemInfo

/**
 *  版本号
 *
 *  @return 版本号
 */
+ (NSString *)appShortVersion {
    NSString *value = [[NSBundle mainBundle]
                       objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    return value;
}

/**
 当前系统版本
 */
+ (NSString *_Nonnull)currentSystemVersion {
    return [[UIDevice currentDevice] systemVersion];
}

/**
 当前语言
 */
+ (NSString *_Nonnull)currentLanguage {
    return [[NSLocale preferredLanguages] objectAtIndex:0];
}

/**
 *   新设备ID
 *   iOS6+ [UIDevice identifierForVendor];
 */
+ (NSString *)deviceId {
    static NSString *deviceId;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        deviceId = [ZLNetKeychainWrapper keychainStringFromMatchingIdentifier:@"deviceId"];
        
        if (!deviceId) {
            deviceId = [[[UIDevice  currentDevice] identifierForVendor] UUIDString];
            
            if (deviceId) {
                [ZLNetKeychainWrapper createKeychainValue:deviceId forIdentifier:@"deviceId"];
            } else {
                NSAssert(0, @"Device ID not found");
                deviceId = [self randomDeviceId];
            }
        }
    });
    return deviceId;
}

+ (NSString *)randomDeviceId {
    srandom([[NSDate date] timeIntervalSince1970]);
    NSString *uniqueId = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", (Byte)random(), (Byte)random(), (Byte)random(), (Byte)random(), (Byte)random(), (Byte)random()];
    return uniqueId;
}

@end
