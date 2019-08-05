//
//  ZLHTTPManager.h
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import <AFNetworking/AFNetworking.h>
#import "ZLBaseModel.h"

// 增加带有 task 的 bloc, 用来判断网络请求
typedef void(^ZLRequestTaskFail)(NSError *error, NSURLSessionDataTask *task);
typedef void(^ZLRequestSuccess)(id responseObject);
typedef void(^ZLRequestProgress)(NSProgress *progress);

// requestSerializer 自定义一些参数
typedef AFHTTPRequestSerializer *(^ZLCustomRequestSerializer)(AFHTTPRequestSerializer *customRequestSerializer);

// 参数加密，或添加自定义参数
typedef NSDictionary *(^ZLRequestEncryptParameters)(NSDictionary *parameters);

// 重新定制请求参数，组装完参数后，会使用block重新操作一遍参数
typedef NSMutableDictionary *(^ZLGeneralParameterBlock)(NSMutableDictionary *parameters);

// 带model的回调
typedef void(^ZLRequestModelSuccess)(ZLBaseModel *responseObject);
typedef void(^ZLRequestModelFail)(ZLBaseModel *error);

// 重新发起网络请求
typedef void(^ZLRestartRequest)(void);

/**
 自定义拦截错误回调block
 @param error ZLBaseModel
 @param successBlock 成功回调
 @param failblock 失败回调
 @param restart 重试方法
 @param jsonModelName  jsonmode 解析类
 */
typedef void(^ZLResponseErrorHandler)(ZLBaseModel *error,
                                        ZLRequestModelSuccess successBlock,
                                        ZLRequestModelFail failblock,
                                        ZLRestartRequest restart,
                                        Class jsonModelName);
typedef void(^ZLNetworkFailHandler)(NSDictionary *errorDict);

/**
 自定义拦截证书错误回调block
 
 @param overdue 是否是过期证书
 @param complete 需要在自己代码完成后，回调complete()
 */
typedef void(^ZLNetworkSSLFailHandler)(BOOL overdue, void(^complete)(void));

typedef NS_ENUM (NSInteger, ZLRetCode) {
    ZLRetCodeJSBridge = 10087,          // JSBridge拦截
    ZLRetCodeSuccess = 0,               // 成功返回码
    ZLRetCodeAuthInvalid = -4,          // 用户登陆失效
    ZLRetCodeNoNetwork = -1009,         // 无网络连接
    ZLRetCodeParameterError = -9999,    // 参数错误
    ZLRetCodeNetError = -99998,         // 网络错误码
    ZLRetCodeJsonParseError = -99999,   // JSON解析失败
};

/**
 组装一个完整的url
 
 @param PATH like：@"/user/login"
 @return aURL
 */
#define BN_API_USER_SERVER_VERSION(PATH) [NSString stringWithFormat:@"%@%@%@", [ZLHTTPManager sharedClient].apiUserServer, [ZLHTTPManager sharedClient].apiVersion ? [NSString stringWithFormat:@"/%@", [ZLHTTPManager sharedClient].apiVersion] : @"", PATH]

/**
 组装一个完整的url， 使用自定义的版本号
 
 @param PATH like：@"/user/login"
 @param VERSION like：@"2.4"
 @return aURL
 */
#define BN_API_CUSTOM_SERVER_VERSION(PATH, VERSION) [NSString stringWithFormat:@"%@%@%@", [ZLHTTPManager sharedClient].apiUserServer, VERSION, PATH]

#define kZLNetworkEverLaunchKey @"kZLNetworkEverLaunchKey"

#define kZLNetworkFirstLaunchKey @"kZLNetworkFirstLaunchKey"

@interface ZLHTTPManager : AFHTTPSessionManager

/**
 *  单例
 */
+ (ZLHTTPManager *)sharedClient;

/**
 服务器地址， like：@"http://bjtestcardloan.xiaoying.com"
 */
@property (nonatomic, copy) NSString *apiUserServer;

/**
 服务器版本号， like：@"2.4"
 */
@property (nonatomic, copy) NSString *apiVersion;

/**
 *  加密秘钥
 */
@property (nonatomic, copy) NSString *serverEncryptSignKey;

/**
 *  自定义 UA
 */
@property (nonatomic, copy) NSString *appUserAgent;

/**
 通用参数字典，每次网络请求会带上此字典中的参数
 */
@property (nonatomic, strong) NSMutableDictionary *generalParaDict NS_DEPRECATED_IOS(2_0, 8_0, "generalParaDict is deprecated. Use generalParameterBlock instead");

/**
 重新定制请求参数，组装完参数后，会使用block重新操作一遍参数
 */
@property (nonatomic, strong) ZLGeneralParameterBlock generalParameterBlock;

/**
 可以自定义errorString，key为错误码，value为errorString
 默认会有以下四个文案，可以自行替换文案：
 @(-1009) : @"网络异常，请检查网络",
 @(-99998) : @"对不起,服务器故障,请稍后重试",
 @(-99999) : @"json解析失败",
 @(-4) : @"请重新登录",
 */
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *errorStringDict;

/**
 网络请求成功，但是服务器返回错误，例 -4重新登陆
 自定义错误回调，key为@(-4)，value：ZLResponseErrorHandler 类型的block
 */
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, ZLResponseErrorHandler> *responseErrorHandlerDict;

/**
 App初次启动 并且当网络连接恢复时 允许重新发出网络请求的URL数组
 */
@property (nonatomic, strong) NSMutableArray<NSString *> *allowedResumableUrls;

/**
 网络错误回调，-500等 用于打点
 */
@property (nonatomic, copy) ZLNetworkFailHandler networkErrorHandle;

/**
 default requestSerializer
 */
@property (nonatomic, strong) AFHTTPRequestSerializer *defaultRequestSerializer;

#pragma mark - 通用网络请求
/**
 GET请求
 *  @param url            url地址
 *  @param parameters     普通参数
 *  @param jsonModelName  使用 jsonModel解析的文件名,留空则不解析
 *  @param success        成功
 *  @param failure        失败
 */
+ (NSURLSessionDataTask *)GET:(NSString *)url
                   parameters:(NSDictionary *)parameters
                jsonModelName:(Class)jsonModelName
                      success:(ZLRequestModelSuccess)success
                      failure:(ZLRequestModelFail)failure;

/**
 POST请求
 *  @param url            url地址
 *  @param parameters     普通参数
 *  @param jsonModelName  使用 jsonModel解析的文件名,留空则不解析
 *  @param fileArray      文件数组，默认为nil,
 *
 *  带上传图片的post请求（Content-Type:multipart/form-data）
 *
 *  如需要上传图片,则需传递一个数组,格式如下
 *
 *    [
 *       {
 *           "file": "文件data",
 *           "fileName": "文件域名字"
 *       }
 *
 *    ]
 *
 *  @param success        成功
 *  @param failure        失败
 *
 *  @return NSURLSessionDataTask NSURLSessionDataTask对象
 */
+ (NSURLSessionDataTask *)POST:(NSString *)url
                    parameters:(NSDictionary *)parameters
                     fileArray:(NSArray *)fileArray
                 jsonModelName:(Class)jsonModelName
                       success:(ZLRequestModelSuccess)success
                uploadProgress:(ZLRequestProgress)uploadProgress
                       failure:(ZLRequestModelFail)failure;

/**
 POST请求
 *  @param url            url地址
 *  @param parameters     普通参数
 *  @param jsonModelName  使用 jsonModel解析的文件名,留空则不解析
 *
 *  普通post请求 (Content-Type:application/x-www-form-urlencoded; charset=utf-8)
 *
 *  @param success        成功
 *  @param failure        失败
 *
 *  @return NSURLSessionDataTask NSURLSessionDataTask对象
 */
+ (NSURLSessionDataTask *)POST:(NSString *)url
                    parameters:(NSDictionary *)parameters
                 jsonModelName:(Class)jsonModelName
                       success:(ZLRequestModelSuccess)success
                       failure:(ZLRequestModelFail)failure;

#pragma mark - 可定制RequestSerializer
/**
 GET请求
 *  @param url            url地址
 *  @param customRequestSerializerCallback            customRequestSerializerCallback
 *  @param parameters     普通参数
 *  @param jsonModelName  使用 jsonModel解析的文件名,留空则不解析
 *  @param success        成功
 *  @param failure        失败
 */
+ (NSURLSessionDataTask *)GET:(NSString *)url
            requestSerializer:(ZLCustomRequestSerializer)customRequestSerializerCallback
                   parameters:(NSDictionary *)parameters
                jsonModelName:(Class)jsonModelName
                      success:(ZLRequestModelSuccess)success
                      failure:(ZLRequestModelFail)failure;

#pragma mark - 可定制encryptParameters
/**
 GET请求
 *  @param url            url地址
 *  @param parameters     普通参数
 *  @param encryptParameters  参数加密
 *  @param jsonModelName  使用 jsonModel解析的文件名,留空则不解析
 *  @param success        成功
 *  @param failure        失败
 */
+ (NSURLSessionDataTask *)GET:(NSString *)url
                   parameters:(NSDictionary *)parameters
                  encryptSign:(ZLRequestEncryptParameters)encryptParameters
                jsonModelName:(Class)jsonModelName
                      success:(ZLRequestModelSuccess)success
                      failure:(ZLRequestModelFail)failure;

/**
 POST请求
 *  @param url            url地址
 *  @param parameters     普通参数
 *  @param encryptParameters  参数加密
 *  @param jsonModelName  使用 jsonModel解析的文件名,留空则不解析
 *  @param fileArray      文件数组，默认为nil,
 *
 *  如需要上传图片,则需传递一个数组,格式如下
 *
 *    [
 *       {
 *           "file": "文件data",
 *           "fileName": "文件域名字"
 *       }
 *
 *    ]
 *
 *  @param success        成功
 *  @param failure        失败
 *
 *  @return NSURLSessionDataTask NSURLSessionDataTask对象
 */
+ (NSURLSessionDataTask *)POST:(NSString *)url
                    parameters:(NSDictionary *)parameters
                   encryptSign:(ZLRequestEncryptParameters)encryptParameters
                     fileArray:(NSArray *)fileArray
                 jsonModelName:(Class)jsonModelName
                       success:(ZLRequestModelSuccess)success
                uploadProgress:(ZLRequestProgress)uploadProgress
                       failure:(ZLRequestModelFail)failure;

#pragma mark - 获取一些基本网络参数信息
/**
 *  设备参数
 *
 *  @return 包含设备参数的dictionary
 */
+ (NSMutableDictionary *)requestDeviceParameters;

#pragma mark - 参数加密方法
/**
 *  默认参数加密方法
 *
 *  @return 包含加密参数的dictionary
 */
+ (NSMutableDictionary *)encryptParameters:(NSMutableDictionary *)parameters;

#pragma mark - 便捷处理方法
/**
 *  单独处理网络异常情况，供其他直接调用
 *
 *  @param failure failure
 */
+ (void)failure:(NSError *)error failure:(ZLRequestModelFail)failure;

/**
 将网络请求回来的数据转为模型
 
 @param jsonModelName 模型类名
 @param responseObject id对象
 @param success 转换成功
 @param failure 转换失败
 */
+ (void)success:(Class)jsonModelName responseObject:(id)responseObject
        success:(ZLRequestModelSuccess)success
        failure:(ZLRequestModelFail)failure;

@end

@interface ZLHTTPManager (HandleSSLError)

/**
 是否校验证书
 
 @param needsCheckSSL YES，校验证书
 @param handler 处理证书错误， 需要在自己代码完成后，回调 complete()
 @warning 在iOS10 及以上，可以正常判断，在iOS10以下的版本 overdue 一直是NO
 */
- (void)needsCheckSSL:(BOOL)needsCheckSSL handler:(ZLNetworkSSLFailHandler)handler;

@end
