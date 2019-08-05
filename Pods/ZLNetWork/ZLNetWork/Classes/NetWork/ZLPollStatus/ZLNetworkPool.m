//
//  ZLNetworkPool.m
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import "ZLNetworkPool.h"

NSString * const ZLNetworkPoolAddTaskNotification = @"ZLNetworkPoolAddTaskNotification";
NSString * const ZLNetworkPoolTaskDidFinishNotification = @"ZLNetworkPoolTaskDidFinishNotification";
NSString * const ZLNetworkPoolTaskDidFailNotification = @"ZLNetworkPoolTaskDidFailNotification";
NSInteger const ZLNetworkPoolDefaultRetryCount = 10;
NSInteger const ZLNetworkPoolDefaultWaitSecond = 3;

static ZLNetworkPool *_shareInstance;

@interface ZLNetworkPool () <ZLNetPollRefreshStatusDelegate>

@property (nonatomic, strong) NSMutableArray <ZLNetPollRefreshStatus *> *pool;

@end

@implementation ZLNetworkPool

+ (instancetype)shareInstance {
    @synchronized (self) {
        if(_shareInstance == nil) {
            _shareInstance = [[self alloc] init];
        }
    }
    return _shareInstance;
}

- (id)init {
    if (self = [super init]) {
        self.pool = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willAddTask:) name:ZLNetworkPoolAddTaskNotification object:nil];
    }
    return self;
}

/**
 *  常驻子线程,用于轮询任务的子线程执行,不影响主线程操作
 */
+ (NSThread *)poolTaskThread {
    static NSThread *poolTaskThread = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        poolTaskThread = [[NSThread alloc] initWithTarget:self selector:@selector(poolTaskThreadEntryPoint:) object:nil];
        [poolTaskThread start];
    });
    return poolTaskThread;
}

+ (void)poolTaskThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:NSStringFromClass(self)];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop run];
    }
}

- (void)willAddTask:(NSNotification *)notiObject {
    NSDictionary *userInfo = notiObject.userInfo;
    ZLNetPollRefreshStatus *task = [userInfo valueForKey:@"task"];
    [self addTask:task];
}

- (void)addTask:(ZLNetPollRefreshStatus *)task {
    
    if (task && [task isValid]) {
        [self fullTask:task];
        [self.pool addObject:task];
        task.delegate = self;
        // 常驻子线程由于AFN没有生效
        [task performSelector:@selector(start) onThread:[[self class] poolTaskThread] withObject:nil waitUntilDone:NO modes:[[NSSet setWithObject:NSRunLoopCommonModes] allObjects]];
    }
}

/**
 *  完整一些必要的字段,防止外部少传入参数问题
 */
- (void)fullTask:(ZLNetPollRefreshStatus *)task {
    task.retryCount = self.retryCount > 0 ? self.retryCount : ZLNetworkPoolDefaultRetryCount;
    task.waitSecond = self.waitSecond > 0 ? self.waitSecond : ZLNetworkPoolDefaultWaitSecond;
}

#pragma mark -- ZLNetPollRefreshStatusDelegate

- (void)ZLNetPollRefreshStatusDidFinish:(ZLNetPollRefreshStatus *)task error:(ZLBaseModel *)error{
    [self.pool removeObject:task];
    if ([self.delegate respondsToSelector:@selector(ZLNetworkPool:didFinishTask:error:)]) {
        [self.delegate ZLNetworkPool:self didFinishTask:task error:error];
    }
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ZLNetworkPoolTaskDidFailNotification object:nil userInfo:@{@"task" : task}];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:ZLNetworkPoolTaskDidFinishNotification object:nil userInfo:@{@"task" : task}];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
