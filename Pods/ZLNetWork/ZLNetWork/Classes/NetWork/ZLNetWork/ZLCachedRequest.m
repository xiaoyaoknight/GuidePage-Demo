//
//  ZLCachedRequest.m
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import "ZLCachedRequest.h"

@implementation ZLCachedRequest

/**
 *  get请求的便利初始化方法
 */
- (instancetype)initGetRequestWithUrl:(NSString *)url
                           parameters:(NSDictionary *)parameters
                    encryptParameters:(ZLRequestEncryptParameters)encryptParameters
                        jsonModelName:(Class)jsonModelName
                              success:(ZLRequestSuccess)success
                              failure:(ZLRequestModelFail)failure {
    
    self = [super init];
    if (self) {
        
        self.requestType = ZLRequestTypeGet;
        self.url = url;
        self.parameters = parameters;
        self.encryptParameters = encryptParameters;
        self.jsonModelName = jsonModelName;
        self.success = success;
        self.failure = failure;
    }
    return self;
}

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
                               failure:(ZLRequestModelFail)failure {
    
    self = [super init];
    if (self) {
        
        self.requestType = ZLRequestTypeGet;
        self.url = url;
        self.parameters = parameters;
        self.encryptParameters = encryptParameters;
        self.fileArray = fileArray;
        self.jsonModelName = jsonModelName;
        self.success = success;
        self.progress = uploadProgress;
        self.failure = failure;
    }
    return self;
}

/**
 *  重新发起请求
 */
- (NSURLSessionDataTask *)resume {
    
    if (self.requestType == ZLRequestTypeGet) {
        return [self getRequestResume];
    } else if (self.requestType == ZLRequestTypePost) {
        return [self postRequestResume];
    }
    return [NSURLSessionDataTask new];
}

- (NSURLSessionDataTask *)getRequestResume {
    
    return [ZLHTTPManager GET:self.url
                     parameters:self.parameters
                    encryptSign:self.encryptParameters
                  jsonModelName:self.jsonModelName
                        success:self.success
                        failure:self.failure];
}

- (NSURLSessionDataTask *)postRequestResume {
    
    return [ZLHTTPManager POST:self.url
                      parameters:self.parameters
                     encryptSign:self.encryptParameters
                       fileArray:self.fileArray
                   jsonModelName:self.jsonModelName
                         success:self.success
                  uploadProgress:self.progress
                         failure:self.failure];
}

@end
