//
//  ZLCachedRequest.h
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import <Foundation/Foundation.h>
#import "ZLHTTPManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZLRequestType) {
    ZLRequestTypeGet = 1,// get请求
    ZLRequestTypePost// post请求
};

@interface ZLCachedRequest : NSObject

/**
 *  请求的类型
 */
@property (nonatomic, assign) ZLRequestType requestType;

/**
 *  请求的URL
 */
@property (nonatomic, strong) NSString *url;

/**
 *  请求参数构成的字典
 */
@property (nonatomic, strong) NSDictionary *parameters;

/**
 *  自定义的参数加密Block
 */
@property (nonatomic, copy) ZLRequestEncryptParameters encryptParameters;

/**
 *  请求结果Model的类
 */
@property (nonatomic, strong) Class jsonModelName;

/**
 *  Post请求时附带的二进制数据文件数组
 */
@property (nonatomic, strong) NSArray *fileArray;

/**
 *  请求成功时回调的Block
 */
@property (nonatomic, copy) ZLRequestSuccess success;

/**
 *  请求进度变化回调的Block
 */
@property (nonatomic, copy) ZLRequestProgress progress;

/**
 *  请求失败回调的Block
 */
@property (nonatomic, copy) ZLRequestModelFail failure;

/**
 *  get请求的便利初始化方法
 */
- (instancetype)initGetRequestWithUrl:(NSString *)url
                           parameters:(NSDictionary *)parameters
                    encryptParameters:(ZLRequestEncryptParameters)encryptParameters
                        jsonModelName:(Class)jsonModelName
                              success:(ZLRequestSuccess)success
                              failure:(ZLRequestModelFail)failure;

/**
 *  post请求的便利初始化方法
 */
- (instancetype)initPostRequestWithUrl:(NSString *)url
                            parameters:(NSDictionary *)parameters
                     encryptParameters:(ZLRequestEncryptParameters)encryptParameters
                             fileArray:(NSArray *)fileArray
                         jsonModelName:(Class)jsonModelName
                        uploadProgress:(ZLRequestProgress)uploadProgress
                               success:(ZLRequestSuccess)success
                               failure:(ZLRequestModelFail)failure;

/**
 *  重新发起请求
 */
- (NSURLSessionDataTask *)resume;
@end

NS_ASSUME_NONNULL_END
