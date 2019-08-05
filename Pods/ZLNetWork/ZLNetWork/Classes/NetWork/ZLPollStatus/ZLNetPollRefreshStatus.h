//
//  ZLNetPollRefreshStatus.h
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import <Foundation/Foundation.h>
#import "ZLCachedRequest.h"
#import "ZLHTTPManager.h"

@class ZLNetPollRefreshStatus;
@protocol ZLNetPollRefreshStatusDelegate <NSObject>

/**
 * 轮询任务完成通知轮询池
 */
- (void)ZLNetPollRefreshStatusDidFinish:(ZLNetPollRefreshStatus *)task error:(ZLBaseModel *)error;

@end

/**
 一次接口请求成功block
 
 @param response         返回值
 @param currenRetryCount 当前重试次数
 @return BOOL            YES 成功-停止轮询
 */
typedef BOOL (^PollRefreshStatusSuccess)(id response, NSInteger currenRetryCount);
/**
 一次接口请求失败block
 
 @param response         返回值
 @param currenRetryCount 当前重试次数
 @return BOOL            YES 成功-停止轮询
 */
typedef BOOL (^PollRefreshStatusFail)(id response, NSInteger currenRetryCount);

/**
 轮询任务完成回调方法,调用者可以实现该回调接收消息
 
 @param response         返回值
 @param currenRetryCount 当前重试次数
 @return error           nil==success non-nill==fail
 */
typedef BOOL (^PollRefreshStatusCompletion)(id response, NSInteger currenRetryCount, ZLBaseModel *error);


@interface ZLNetPollRefreshStatus : ZLCachedRequest

@property (nonatomic, copy) PollRefreshStatusSuccess pollRefreshStatusSuccess;

@property (nonatomic, copy) PollRefreshStatusFail pollRefreshStatusFail;

@property (nonatomic, copy) PollRefreshStatusCompletion pollRefreshStatusCompletion;

/**
 * 轮询任务总共重试次数
 */
@property (nonatomic, assign) NSInteger retryCount;

/**
 * 轮询任务每次请求接口等待时间
 */
@property (nonatomic, assign) NSInteger waitSecond;

@property (nonatomic, weak) id<ZLNetPollRefreshStatusDelegate> delegate;

/**
 * 存储额外信息,用于通知接收方的比对
 */
@property (nonatomic, strong) id userInfo;

/**
 * 开启一个轮询任务
 */
- (void)start;

/**
 * 外部传进来轮询任务是否valid
 */
- (BOOL)isValid;

@end

