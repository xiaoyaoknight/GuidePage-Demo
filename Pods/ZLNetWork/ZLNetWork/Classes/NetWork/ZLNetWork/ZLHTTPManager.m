//
//  ZLHTTPManager.m
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import "ZLHTTPManager.h"
#import <AssertMacros.h>
#import <Security/Security.h>
#import "ZLCachedRequest.h"
#import "ZLNetSystemInfo.h"
#import "NSMutableDictionary+ZLNetSerialize.h"
#import "ZLHttpsCheck.h"
#import <objc/runtime.h>

@interface NSURLSessionTask (UIBackgroundTaskIdentifier)

@property(nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

@implementation NSURLSessionTask (UIBackgroundTaskIdentifier)

static void *DataTaskBackgroundTaskIdentifier = &DataTaskBackgroundTaskIdentifier;
- (void)setBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier {
    objc_setAssociatedObject(self, &DataTaskBackgroundTaskIdentifier, @(backgroundTaskIdentifier), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIBackgroundTaskIdentifier)backgroundTaskIdentifier {
    id identifier = objc_getAssociatedObject(self, &DataTaskBackgroundTaskIdentifier);
    if (identifier == nil) {
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        identifier = @(UIBackgroundTaskInvalid);
    }
    return [identifier unsignedIntegerValue];
}

@end

@interface ZLHTTPManager()

@property (nonatomic, assign) BOOL isHandlingSSLError;

/**
 *  缓存因无网络导致网络请求失败并且在网络恢复后允许重新发起网络请求的包含网络请求的字典
 */
@property (nonatomic, strong) NSMutableDictionary *launchFailureRequestsCache;

@end

@implementation ZLHTTPManager

+ (ZLHTTPManager *)sharedClient {
    static ZLHTTPManager *httpManagersharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        httpManagersharedClient = [self manager];
        httpManagersharedClient.responseSerializer = [AFJSONResponseSerializer serializer];
        httpManagersharedClient.defaultRequestSerializer = [[AFHTTPRequestSerializer alloc] init];
        httpManagersharedClient.defaultRequestSerializer.HTTPShouldHandleCookies = YES;
        [httpManagersharedClient.defaultRequestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [httpManagersharedClient setLaunchStatus];
        [httpManagersharedClient monitorNetworkStatusChange];
        [ZLHTTPManager setAppCookie];
    });
    return httpManagersharedClient;
}

/// fix iOS12 程序进入后台后，网络请求会发生 domain=NSPOSIXErrorDomain code=53 的错误
/// 使程序进入后台后，还可以执行任务
+ (void)start:(NSURLSessionDataTask *)task {
    if (task.backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        // 开始新的任务
        task.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [self finish:task];
        }];
    }
}

+ (void)finish:(NSURLSessionDataTask *)task {
    if (task.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:task.backgroundTaskIdentifier];
        task.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
}

#pragma mark - 基础GET方法(内部调用AFN方法)
+ (NSURLSessionDataTask *)GET:(NSString *)url
            requestSerializer:(ZLCustomRequestSerializer)customRequestSerializerCallback
                   parameters:(NSDictionary *)parameters
                      success:(ZLRequestSuccess)success
                      failure:(ZLRequestTaskFail)failure {
    AFHTTPSessionManager *manager = [ZLHTTPManager sharedClient];
    if (customRequestSerializerCallback) {
        manager.requestSerializer = customRequestSerializerCallback([[self sharedClient].defaultRequestSerializer copy]);
    } else {
        manager.requestSerializer = [self sharedClient].defaultRequestSerializer;
    }
    [manager.requestSerializer setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *operation = [manager GET:url
                                        parameters:parameters
                                          progress:^(NSProgress * _Nonnull downloadProgress) {
                                              
                                          } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                              [self finish:task];
                                              if (success) {
                                                  success(responseObject);
                                              }
                                          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                              [self finish:task];
                                              if (failure) {
                                                  failure(error, task);
                                              }
                                          }];
    [self start:operation];
    return operation;
}

#pragma mark - 基础POST 表单文件上传方法(内部调用AFN方法)
+ (NSURLSessionDataTask *)POST:(NSString *)url
                    parameters:(NSDictionary *)parameters
                     fileArray:(NSArray *)fileArray
                       success:(ZLRequestSuccess)success
                      progress:(ZLRequestProgress)progress
                       failure:(ZLRequestTaskFail)failure {
    
    ZLHTTPManager *manager = [ZLHTTPManager sharedClient];
    manager.requestSerializer = manager.defaultRequestSerializer;
    [manager.requestSerializer setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *operation = [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        if (fileArray) {
            for (NSDictionary *dict in fileArray) {
                NSData *data = [dict objectForKey:@"file"];
                NSString *fileName = @"";
                
                if (data) {
                    if ([dict objectForKey:@"fileName"]) {
                        fileName = [dict objectForKey:@"fileName"];
                    }
                    
                    [formData appendPartWithFileData:data name:fileName fileName:fileName mimeType:@"image/jpg/file"];
                }
            }
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self finish:task];
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self finish:task];
        if (failure) {
            failure(error, task);
        }
    }];
    
    [self start:operation];
    return operation;
}

#pragma mark - 基础POST方法(内部调用AFN方法)
+ (NSURLSessionDataTask *)POST:(NSString *)url
             requestSerializer:(ZLCustomRequestSerializer)customRequestSerializerCallback
                    parameters:(NSDictionary *)parameters
                       success:(ZLRequestSuccess)success
                       failure:(ZLRequestTaskFail)failure {
    
    AFHTTPSessionManager *manager = [ZLHTTPManager sharedClient];
    if (customRequestSerializerCallback) {
        manager.requestSerializer = customRequestSerializerCallback([[ZLHTTPManager sharedClient].defaultRequestSerializer copy]);
    } else {
        manager.requestSerializer = [ZLHTTPManager sharedClient].defaultRequestSerializer;
    }
    [manager.requestSerializer setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *operation = [manager POST:url
                                         parameters:parameters
                                            success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                                [self finish:task];
                                                if (success) {
                                                    success(responseObject);
                                                }
                                            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                                [self finish:task];
                                                if (failure) {
                                                    failure(error,task);
                                                }
                                            }];
    [self start:operation];
    return operation;
}


#pragma mark - 对外暴露网络请求方法
+ (NSURLSessionDataTask *)GET:(NSString *)url
                   parameters:(NSDictionary *)parameters
                jsonModelName:(Class)jsonModelName
                      success:(ZLRequestModelSuccess)success
                      failure:(ZLRequestModelFail)failure {
    
    return [self GET:url requestSerializer:nil parameters:parameters encryptSign:nil jsonModelName:jsonModelName success:success failure:failure];
}

+ (NSURLSessionDataTask *)POST:(NSString *)url
                    parameters:(NSDictionary *)parameters
                     fileArray:(NSArray *)fileArray
                 jsonModelName:(Class)jsonModelName
                       success:(ZLRequestModelSuccess)success
                uploadProgress:(ZLRequestProgress)uploadProgress
                       failure:(ZLRequestModelFail)failure {
    
    return [self POST:url parameters:parameters encryptSign:nil fileArray:fileArray jsonModelName:jsonModelName success:success uploadProgress:uploadProgress failure:failure];
}

+ (NSURLSessionDataTask *)POST:(NSString *)url
                    parameters:(NSDictionary *)parameters
                 jsonModelName:(Class)jsonModelName
                       success:(ZLRequestModelSuccess)success
                       failure:(ZLRequestModelFail)failure {
    NSMutableDictionary *data = [self _preprocess:parameters encryptSign:nil];
    return [self POST:url parameters:data success:^(id responseObject) {
        [self _processResponseObject:responseObject
                       jsonModelName:jsonModelName
                             success:(ZLRequestModelSuccess)success
                             failure:(ZLRequestModelFail)failure
                             restart:^{
                                 [self POST:url
                                 parameters:parameters
                              jsonModelName:jsonModelName
                                    success:success
                                    failure:failure];
                             }];
    } failure:^(NSError *error, NSURLSessionDataTask *task) {
        [self _handlingNetworkErrors:error task:task failure:failure];
        
        // 首次启动无网请求
        if (error.code == ZLRetCodeNoNetwork && [[self sharedClient] isFirstLaunch] && [[self sharedClient].allowedResumableUrls containsObject:url]) {
            ZLCachedRequest *cachedRequest = [[ZLCachedRequest alloc] initPostRequestWithUrl:url
                                                                                              parameters:parameters
                                                                                       encryptParameters:nil
                                                                                               fileArray:nil
                                                                                           jsonModelName:jsonModelName
                                                                                          uploadProgress:nil
                                                                                                 success:success
                                                                                                 failure:failure];
            [[self sharedClient].launchFailureRequestsCache setObject:cachedRequest forKey:url];
        }
    }];
}

#pragma mark - 其他内部网络请求包装方法
+ (NSURLSessionDataTask *)GET:(NSString *)url
            requestSerializer:(ZLCustomRequestSerializer)customRequestSerializerCallback
                   parameters:(NSDictionary *)parameters
                jsonModelName:(Class)jsonModelName
                      success:(ZLRequestModelSuccess)success
                      failure:(ZLRequestModelFail)failure {
    
    return [self GET:url requestSerializer:customRequestSerializerCallback parameters:parameters encryptSign:nil jsonModelName:jsonModelName success:success failure:failure];
}

// 可定制encryptParameters
+ (NSURLSessionDataTask *)GET:(NSString *)url
                   parameters:(NSDictionary *)parameters
                  encryptSign:(ZLRequestEncryptParameters)encryptParameters
                jsonModelName:(Class)jsonModelName
                      success:(ZLRequestModelSuccess)success
                      failure:(ZLRequestModelFail)failure {
    
    return [self GET:url requestSerializer:nil parameters:parameters encryptSign:encryptParameters jsonModelName:jsonModelName success:success failure:failure];
}

// 可定制encryptParameters
+ (NSURLSessionDataTask *)POST:(NSString *)url
                    parameters:(NSDictionary *)parameters
                   encryptSign:(ZLRequestEncryptParameters)encryptParameters
                     fileArray:(NSArray *)fileArray
                 jsonModelName:(Class)jsonModelName
                       success:(ZLRequestModelSuccess)success
                uploadProgress:(ZLRequestProgress)uploadProgress
                       failure:(ZLRequestModelFail)failure {
    
    NSMutableDictionary *data = [self _preprocess:parameters encryptSign:encryptParameters];
    return [self POST:url parameters:data fileArray:fileArray success:^(id responseObject) {
        [self _processResponseObject:responseObject
                       jsonModelName:jsonModelName
                             success:(ZLRequestModelSuccess)success
                             failure:(ZLRequestModelFail)failure
                             restart:^{
                                 [self POST:url
                                 parameters:parameters
                                encryptSign:encryptParameters
                                  fileArray:fileArray
                              jsonModelName:jsonModelName
                                    success:success
                             uploadProgress:uploadProgress
                                    failure:failure];
                             }];
    } progress:^(NSProgress *progress) {
        if (uploadProgress) {
            uploadProgress(progress);
        }
    } failure:^(NSError *error, NSURLSessionDataTask *task) {
        [self _handlingNetworkErrors:error task:task failure:failure];
        
        // 首次启动无网请求
        if (error.code == ZLRetCodeNoNetwork && [[self sharedClient] isFirstLaunch] && [[self sharedClient].allowedResumableUrls containsObject:url]) {
            ZLCachedRequest *cachedRequest = [[ZLCachedRequest alloc] initPostRequestWithUrl:url
                                                                                              parameters:parameters
                                                                                       encryptParameters:encryptParameters
                                                                                               fileArray:fileArray
                                                                                           jsonModelName:jsonModelName
                                                                                          uploadProgress:uploadProgress
                                                                                                 success:success
                                                                                                 failure:failure];
            [[self sharedClient].launchFailureRequestsCache setObject:cachedRequest forKey:url];
        }
    }];
}

+ (NSURLSessionDataTask *)POST:(NSString *)url
                    parameters:(NSDictionary *)parameters
                       success:(ZLRequestSuccess)success
                       failure:(ZLRequestTaskFail)failure {
    return [self POST:url requestSerializer:nil parameters:parameters success:success failure:failure];
}

#pragma mark - 完整请求，可定制 RequestSerializer、encryptParameters、jsonModelName
+ (NSURLSessionDataTask *)GET:(NSString *)url
            requestSerializer:(ZLCustomRequestSerializer)customRequestSerializerCallback
                   parameters:(NSDictionary *)parameters
                  encryptSign:(ZLRequestEncryptParameters)encryptParameters
                jsonModelName:(Class)jsonModelName
                      success:(ZLRequestModelSuccess)success
                      failure:(ZLRequestModelFail)failure {
    
    NSMutableDictionary *data = [self _preprocess:parameters encryptSign:encryptParameters];
    return [self GET:url requestSerializer:customRequestSerializerCallback parameters:data success:^(id responseObject) {
        
        [self _processResponseObject:responseObject
                       jsonModelName:jsonModelName
                             success:(ZLRequestModelSuccess)success
                             failure:(ZLRequestModelFail)failure
                             restart:^{
                                 [self GET:url parameters:data jsonModelName:jsonModelName success:success failure:failure];
                             }];
    } failure:^(NSError *error, NSURLSessionDataTask *task) {
        [self _handlingNetworkErrors:error task:task failure:failure];
        
        // 首次启动无网请求
        if (error.code == ZLRetCodeNoNetwork && [[self sharedClient] isFirstLaunch] && [[self sharedClient].allowedResumableUrls containsObject:url]) {
            ZLCachedRequest *cachedRequest = [[ZLCachedRequest alloc] initGetRequestWithUrl:url
                                                                                             parameters:data
                                                                                      encryptParameters:encryptParameters
                                                                                          jsonModelName:jsonModelName
                                                                                                success:success
                                                                                                failure:failure];
            [[self sharedClient].launchFailureRequestsCache setObject:cachedRequest forKey:url];
        }
    }];
}

/**
 处理返回成功时候的数据
 
 @param jsonModelName jsonModelClass
 @param restart 重新发起网络请求block
 */
+ (void)_processResponseObject:responseObject
                 jsonModelName:(Class)jsonModelName
                       success:(ZLRequestModelSuccess)success
                       failure:(ZLRequestModelFail)failure
                       restart:(ZLRestartRequest)restart {
    
    [self success:jsonModelName responseObject:responseObject success:^(id responseObject) {
        
        // 转 model 时已经对jsbridge转换了，此处不用再判断
        if (![responseObject isKindOfClass:[ZLBaseModel class]]) {
            success(responseObject);
            return ;
        }
        
        ZLResponseErrorHandler responseErrorHandler = [[self sharedClient].responseErrorHandlerDict objectForKey:@(((ZLBaseModel *)responseObject).errcode)];
        if (responseErrorHandler) {
            // error 回调时,将 success 回调也同时传递,某 app 可能需要用到
            responseErrorHandler((ZLBaseModel *)responseObject, success, failure, restart, jsonModelName);
        } else {
            success(responseObject);
        }
    } failure:^(ZLBaseModel *error) {
        ZLResponseErrorHandler responseErrorHandler = [[self sharedClient].responseErrorHandlerDict objectForKey:@(error.errcode)];
        if (responseErrorHandler) {
            // error 回调时,将 success 回调也同时传递,某 app 可能需要用到
            responseErrorHandler(error, success, failure, restart, jsonModelName);
        } else {
            failure((ZLBaseModel *)error);
        }
    }];
}

/**
 网络错误处理
 */
+ (void)_handlingNetworkErrors:(NSError *)error
                          task:(NSURLSessionDataTask *)task
                       failure:(ZLRequestModelFail)failure {
    // 网络错误上报
    if ([self sharedClient].networkErrorHandle) {
        NSDictionary *netErrorDict = [self getNetworkError:error dataTask:task];
        if (netErrorDict) {
            [self sharedClient].networkErrorHandle(netErrorDict);
        }
    }
    
    [self failure:error failure:^(ZLBaseModel *error) {
        failure((ZLBaseModel *)error);
    }];
}

/**
 参数预处理
 */
+ (NSMutableDictionary *)_preprocess:(NSDictionary *)parameters encryptSign:(ZLRequestEncryptParameters)encryptParameters {
    
    NSMutableDictionary *data = [self requestDeviceParameters];
    [data addEntriesFromDictionary:parameters];
    
    //重新登陆，会多一个sign参数
    if (data[@"sign"]) [data removeObjectForKey:@"sign"];
    
    // // 添加通用参数，自定义如ua，channel参数
    if ([self sharedClient].generalParaDict) {
        [data addEntriesFromDictionary:[self sharedClient].generalParaDict];
    }
    
    // 统一处理参数block
    if ([self sharedClient].generalParameterBlock) {
        data = [self sharedClient].generalParameterBlock(data);
    }
    
    if (encryptParameters) {
        data = [encryptParameters(data) mutableCopy];
    } else {
        // 加密
        data = [self encryptParameters:data];
    }
    
    if ([self sharedClient].appUserAgent) {
        [[self sharedClient].defaultRequestSerializer setValue:[self sharedClient].appUserAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    return data;
}

#pragma mark - convenient method

/**
 *  设置  公共 cookie
 */
+ (void)setAppCookie {
    // 逻辑 cookie
    NSMutableDictionary *logicCookie = [NSMutableDictionary dictionaryWithCapacity:0];
    
    [logicCookie setObject:[ZLNetSystemInfo appShortVersion] forKey:@"app_version"];
    [logicCookie setObject:[ZLNetSystemInfo currentSystemVersion] forKey:@"os_version"];
    [logicCookie setObject:[ZLNetSystemInfo currentLanguage] forKey:@"language"];
    [logicCookie setObject:[ZLNetSystemInfo deviceId] forKey:@"mac_id"];
    [logicCookie setObject:@"ios" forKey:@"plat"];
    
    for (NSString *key in logicCookie) {
        [ZLHTTPManager setCookie:key value:[logicCookie objectForKey:key]];
    }
}

/**
 *  设置 cookie
 */
+ (void)setCookie:(NSString *)key value:(NSString *)value  {
    NSMutableDictionary *cookieDic = [NSMutableDictionary dictionary];
    
    [cookieDic setObject:key forKey:NSHTTPCookieName];
    [cookieDic setValue:value forKey:NSHTTPCookieValue];
    
    NSHTTPCookie *cookieuser = [NSHTTPCookie cookieWithProperties:cookieDic];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookieuser];
}

/**
 *  设置是否为第一次启动
 */
- (void)setLaunchStatus {
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kZLNetworkEverLaunchKey]) {
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kZLNetworkEverLaunchKey];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kZLNetworkFirstLaunchKey];
    } else {
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kZLNetworkFirstLaunchKey];
    }
}

/**
 * 监听网络连接变化 当网络恢复时重新发出网络请求
 */
- (void)monitorNetworkStatusChange {
    
    if ([self isFirstLaunch]) {
        
        AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
        [manager startMonitoring];
        __weak typeof(manager) weak_manager = manager;
        [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            __strong typeof(weak_manager) strong_manager = weak_manager;
            if ((status == AFNetworkReachabilityStatusReachableViaWiFi || status == AFNetworkReachabilityStatusReachableViaWWAN) && self.launchFailureRequestsCache.count > 0) {
                
                [self.launchFailureRequestsCache enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    
                    ZLCachedRequest *cachedRequest = obj;
                    [cachedRequest resume];
                }];
                
                // 恢复一次网络后 不再缓存
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kZLNetworkFirstLaunchKey];
                [self.launchFailureRequestsCache removeAllObjects];
                [strong_manager stopMonitoring];
            }
        }];
    }
}

/**
 *  判断是否是第一次启动的便捷方法
 */
- (BOOL)isFirstLaunch {
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:kZLNetworkFirstLaunchKey];
}

/**
 *  默认参数加密方法
 *
 *  @return 包含加密参数的dictionary
 */
+ (NSMutableDictionary *)encryptParameters:(NSMutableDictionary *)parameters {
    // 加密
    [parameters serializeDictToOauth1:[self sharedClient].serverEncryptSignKey appendDict:@{@"ut":@((NSInteger)[[NSDate date] timeIntervalSince1970])}];
    return parameters;
}

/**
 将网络请求回来的数据转为模型
 
 @param jsonModelName 模型类名
 @param responseObject id对象
 @param success 转换成功
 @param failure 转换失败
 */
+ (void)success:(Class)jsonModelName
 responseObject:(id)responseObject
        success:(ZLRequestModelSuccess)success
        failure:(ZLRequestModelFail)failure {
    
    if ([responseObject isKindOfClass:[NSData class]]) {
        //objectFromJSONData
        responseObject = [((NSData *)responseObject) objectFromJSONData];
    }
    
    NSError *error = nil;
    ZLBaseModel *model = nil;
    
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        model = [self creatErrorBaseModel:ZLRetCodeJsonParseError];
    } else {
        NSNumber *errorcode = [responseObject objectForKey:@"errcode"];
        
        // 判断jsbridge类型
        if (errorcode && [errorcode integerValue] == ZLRetCodeJSBridge) {
            model = [[ZLBaseModel alloc] initWithDictionary:responseObject error:&error];
            success(model);
            return;
        }
        
        // 判断errcode < 0 的判断， 因为model都忽略了字段，errorcode可能匹配不到, data.
        if (errorcode && [errorcode integerValue] < 0) {
            model = [[ZLBaseModel alloc] initWithDictionary:responseObject error:&error];
            failure(model);
            return;
        }
        
        // 正常情况下，如果jsonModelName为空，则直接返回字典
        if (jsonModelName == nil) {
            success(responseObject);
            return;
        }
        
        // 根据 jsonModelName 解析数据
        model = [[jsonModelName alloc] initWithDictionary:responseObject error:&error];
        if (error) {
            model = [self creatErrorBaseModel:ZLRetCodeJsonParseError];
        }
        
        if (model.errcode >= 0) {
            success(model);
        } else {
            failure(model);
        }
        return;
    }
}


/**
 获取app基本信息
 */
+ (NSMutableDictionary *)requestDeviceParameters {
    NSMutableDictionary *deviceData = [NSMutableDictionary  dictionary];
    
    [deviceData setObject:[ZLNetSystemInfo appShortVersion] forKey:@"soft_version"];
    [deviceData setObject:[ZLNetSystemInfo currentSystemVersion] forKey:@"os_version"];
    [deviceData setObject:[ZLNetSystemInfo currentLanguage] forKey:@"language"];
    [deviceData setObject:[ZLNetSystemInfo deviceId] forKey:@"mac_id"];//设备id
    [deviceData setObject:@"ios" forKey:@"os"];
    return deviceData;
}

+ (void)failure:(NSError *)error failure:(ZLRequestModelFail)failure {
    
    ZLBaseModel *model = nil;
    if (error && [[self sharedClient].errorStringDict objectForKey:@(error.code)]) {
        model = [self creatErrorBaseModel:(error.code)];
    } else {
        model = [self creatErrorBaseModel:ZLRetCodeNetError];
    }
    model.networkError = error;
    failure(model);
}

+ (ZLBaseModel *)creatErrorBaseModel:(NSInteger)errorCode {
    ZLBaseModel *model = [[ZLBaseModel alloc] init];
    model.errcode = errorCode;
    model.errstr = [[ZLHTTPManager sharedClient].errorStringDict objectForKey:@(errorCode)];
    model.errstr = model.errstr == nil ? @"" : model.errstr;
    return model;
}

/**
 从task和error中收集网络错误信息
 */
+ (NSDictionary *)getNetworkError:(NSError *)error dataTask:(NSURLSessionDataTask *)task {
    
    if (error.code == NSURLErrorTimedOut
        || error.code == NSURLErrorCannotConnectToHost
        || error.code == NSURLErrorHTTPTooManyRedirects
        || error.code == NSURLErrorCannotConnectToHost
        || error.code == NSURLErrorRedirectToNonExistentLocation
        || error.code == NSURLErrorBadServerResponse) {
        
        NSMutableDictionary *errorDict = [NSMutableDictionary dictionary];
        
        if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
            [errorDict setObject:@(((NSHTTPURLResponse *)task.response).statusCode) forKey:@"errorCode"];
        } else {
            [errorDict setObject:@(error.code) forKey:@"errorCode"];
        }
        if (task.currentRequest.URL.absoluteString) {
            [errorDict setObject:task.currentRequest.URL.absoluteString forKey:@"errorUrl"];
        }
        return errorDict;
    }
    return nil;
}

#pragma mark - getter
- (NSMutableDictionary *)generalParaDict {
    if (_generalParaDict == nil) {
        _generalParaDict = [NSMutableDictionary dictionary];
    }
    return _generalParaDict;
}

- (NSMutableDictionary *)errorStringDict {
    if (_errorStringDict == nil) {
        _errorStringDict = [@{
                              @(-1009) : @"网络异常，请检查网络",
                              @(-99998) : @"对不起,服务器故障,请稍后重试",
                              @(-99999) : @"json解析失败",
                              @(-4) : @"请重新登录",
                              } mutableCopy];
    }
    return _errorStringDict;
}

- (NSMutableDictionary *)responseErrorHandlerDict {
    if (_responseErrorHandlerDict == nil) {
        _responseErrorHandlerDict = [NSMutableDictionary dictionary];
    }
    return _responseErrorHandlerDict;
}

- (NSMutableDictionary *)launchFailureRequestsCache {
    if (_launchFailureRequestsCache == nil) {
        _launchFailureRequestsCache = [[NSMutableDictionary alloc] init];
    }
    return _launchFailureRequestsCache;
}

- (NSMutableArray<NSString *> *)allowedResumableUrls {
    if (_allowedResumableUrls == nil) {
        _allowedResumableUrls = [[NSMutableArray alloc] init];
    }
    return _allowedResumableUrls;
}

@end


@implementation ZLHTTPManager (HandleSSLError)

/**
 是否校验证书
 
 @param needsCheckSSL YES，校验证书
 @param handler 处理证书错误
 */
- (void)needsCheckSSL:(BOOL)needsCheckSSL handler:(ZLNetworkSSLFailHandler)handler {
    //如果需要设置校验SSL，且已经校验了SSL 或者
    //不需要设置校验SSL，且原来就没有校验SSL
    if ((needsCheckSSL && (self.securityPolicy.SSLPinningMode != AFSSLPinningModeNone)) ||
        (needsCheckSSL == NO && (self.securityPolicy.SSLPinningMode == AFSSLPinningModeNone))) {
        return;
    }
    
    if (needsCheckSSL) {
        // 取证书
        NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"ZLHTTPManager")];
        NSString *bundleName = @"ZLNetwork";
        NSString *path = [bundle pathForResource:bundleName ofType:@"bundle"];
        NSBundle *cerBundle = [NSBundle bundleWithPath:path];
        NSSet *cer = [AFSecurityPolicy certificatesInBundle:cerBundle];
        
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey withPinnedCertificates:cer];
        securityPolicy.validatesDomainName = YES;
        securityPolicy.allowInvalidCertificates = YES;
        self.securityPolicy = securityPolicy;
        
        __weak typeof(self) weakSelf = self;
        [self setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable credential) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                if ([strongSelf.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                    *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                    if (credential) {
                        disposition = NSURLSessionAuthChallengeUseCredential;
                    } else {
                        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                    }
                } else {
                    disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                }
            } else {
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
            
            if (disposition == NSURLSessionAuthChallengeCancelAuthenticationChallenge) {
                
                BOOL expired = YES;
                if (@available(iOS 10, *)) {
                    for (NSData *certData in strongSelf.securityPolicy.pinnedCertificates) {
                        BOOL theExpired = [ZLHttpsCheck session:session cert:certData didReceiveAuthenticationChallenge:challenge];
                        expired = expired && theExpired;
                    }
                } else {
                    // SecTrustEvaluate 在iOS9 及以下会发生crash，暂停使用
                    expired = NO;
                }
                
                // 证书全部过期，提示升级
                if (expired) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf handleSSLError:handler overdue:YES];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [strongSelf handleSSLError:handler overdue:NO];
                    });
                }
            }
            return disposition;
        }];
    } else {
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        self.securityPolicy = securityPolicy;
        [self setSessionDidReceiveAuthenticationChallengeBlock:nil];
    }
}

/**
 处理证书错误回调
 */
- (void)handleSSLError:(ZLNetworkSSLFailHandler)handler
               overdue:(BOOL)overdue {
    if (handler && !self.isHandlingSSLError) {
        self.isHandlingSSLError = YES;
        handler(overdue, ^{
            [ZLHTTPManager sharedClient].isHandlingSSLError = NO;
        });
    }
}


@end

