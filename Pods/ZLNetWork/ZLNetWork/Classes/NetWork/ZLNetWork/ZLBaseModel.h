//
//  ZLBaseModel.h
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import <JSONModel/JSONModel.h>
#import <JSONKit_Framework/JSONKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZLBaseModel : JSONModel

/**
 *  返回对象
 *
 *  @param errcode  返回码
 *  @param errstr   错误信息
 */
- (instancetype)initWithCode:(NSInteger)errcode errstr:(NSString *)errstr;

/**
 *  返回码
 */
@property (nonatomic, assign) NSInteger errcode;

/**
 *  错误信息
 */
@property (nonatomic, strong) NSString *errstr;

/**
 jsbridge 协议
 */
@property (nonatomic, strong) NSString *jsbridge;

/**
 因为网络问题导致的错误、超时，取消等
 */
@property (nonatomic, strong) NSError *networkError;

/**
 *  方便的从 YZTBaseModel 转成 NSError
 */
- (NSError *)error;

@end

NS_ASSUME_NONNULL_END
