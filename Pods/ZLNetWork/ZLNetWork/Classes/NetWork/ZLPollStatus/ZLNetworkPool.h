//
//  ZLNetworkPool.h
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import <Foundation/Foundation.h>
#import "ZLNetPollRefreshStatus.h"

@class ZLNetworkPool;

/**
 *  轮询池代理
 */
@protocol ZLNetworkPoolDelegate <NSObject>

/**
 * 轮询任务完成回调方法,调用者可以实现该方法接收消息
 */
@optional
- (void)ZLNetworkPool:(ZLNetworkPool *)networkPool didFinishTask:(ZLNetPollRefreshStatus *)task error:(ZLBaseModel *)error;

@end

/**
 *  轮询池
 */
@interface ZLNetworkPool : NSObject

@property (nonatomic, weak) id<ZLNetworkPoolDelegate> delegate;

+ (instancetype)shareInstance;

/**
 * 轮询任务总共重试次数
 */
@property (nonatomic, assign) NSInteger retryCount;

/**
 * 轮询任务每次请求接口等待时间
 */
@property (nonatomic, assign) NSInteger waitSecond;

/**
 *  轮询池添加轮询任务
 */
- (void)addTask:(ZLNetPollRefreshStatus *)task;

@end

/**
 *  轮询池接收轮询任务通知
 */
FOUNDATION_EXPORT NSString * const ZLNetworkPoolAddTaskNotification;
/**
 *  轮询任务完成通知
 */
FOUNDATION_EXPORT NSString * const ZLNetworkPoolTaskDidFinishNotification;
/**
 *  轮询任务失败通知
 */
FOUNDATION_EXPORT NSString * const ZLNetworkPoolTaskDidFailNotification;
/**
 *  默认轮询次数
 */
FOUNDATION_EXPORT NSInteger const ZLNetworkPoolDefaultRetryCount;
/**
 *  默认轮询间隔
 */
FOUNDATION_EXPORT NSInteger const ZLNetworkPoolDefaultWaitSecond;


