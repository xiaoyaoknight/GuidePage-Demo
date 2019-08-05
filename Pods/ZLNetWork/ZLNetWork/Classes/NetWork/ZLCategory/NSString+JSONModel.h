//
//  NSString+JSONModel.h
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * 解决在32位机器上JSONModel库json转model的crash问题
 *
 *  在32位CPU下，BOOL为signed char型，NSInteger为int型， 长度和long型均占4个字节
 *  在64位CPU下，BOOL为Bool型，NSInteger为long型， 长度和long long型均占8个字节
 *
 *  后台约定为BOOL和int的参数给成了String型。
 *  JSONModel解析的时候默认按照Number型的数据进行处理. 32位机器系统底层在转换的时候 对NSInteger类型的数据取longValue, 对BOOL型的数据去charValue. 导致解析出现以下错误：
 *
 *  -[__NSCFString charValue]: unrecognized selector sent to instance 0xxxxx
 *  -[__NSCFString longValue]: unrecognized selector sent to instance 0xxxxx
 *
 *  64位机器系统底层在转换的时候 对NSInteger类型的数据取longlongValue, 对BOOL型的数据去boolValue. 而`String`型均包含这些方法。所以不会出现问题。
 */

@interface NSString (JSONModel)

#if __LP64__ || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
#else
@property (nonatomic, assign, readonly) NSInteger longValue;
@property (nonatomic, assign, readonly) BOOL charValue;
#endif

@end

NS_ASSUME_NONNULL_END
