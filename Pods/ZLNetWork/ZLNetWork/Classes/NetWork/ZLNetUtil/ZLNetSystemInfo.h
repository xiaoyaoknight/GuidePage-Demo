//
//  ZLNetSystemInfo.h
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZLNetSystemInfo : NSObject

/**
 *  版本号
 *
 *  @return 版本号
 */
+ (NSString * _Nonnull)appShortVersion;

/**
 当前系统版本
 */
+ (NSString *_Nonnull)currentSystemVersion;

/**
 当前语言
 */
+ (NSString *_Nonnull)currentLanguage;

/**
 *   新设备ID
 *   iOS6+ [UIDevice identifierForVendor];
 */
+ (NSString *_Nullable)deviceId;
@end

NS_ASSUME_NONNULL_END
