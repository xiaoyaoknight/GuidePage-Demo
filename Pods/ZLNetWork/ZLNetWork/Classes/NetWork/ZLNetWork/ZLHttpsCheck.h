//
//  ZLHttpsCheck.h
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZLHttpsCheck : NSObject

/**
 验证证书是否是过期证书
 
 @return YES, 过期
 */
+ (BOOL)session:(NSURLSession *)session cert:(NSData *)certData didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
@end

NS_ASSUME_NONNULL_END
