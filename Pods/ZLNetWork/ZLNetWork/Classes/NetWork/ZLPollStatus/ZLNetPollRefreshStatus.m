//
//  ZLNetPollRefreshStatus.m
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import "ZLNetPollRefreshStatus.h"

@interface ZLNetPollRefreshStatus ()

// 记录请求状态接口次数
@property (nonatomic, assign) NSInteger refreshStatusCount;

// 网络请求
@property (nonatomic, weak) NSURLSessionDataTask *dataTask;

@end

@implementation ZLNetPollRefreshStatus

- (void)start {
    [self loadRequest:self.url
               params:self.parameters
       jsonModelClass:self.jsonModelName
pollRefreshStatusSuccess:self.pollRefreshStatusSuccess
pollRefreshStatusFail:self.pollRefreshStatusFail];
}

- (void)loadRequest:(NSString *)url
             params:(NSDictionary *)params
     jsonModelClass:(Class)jsonModelClass
pollRefreshStatusSuccess:(PollRefreshStatusSuccess)pollRefreshStatusSuccess
pollRefreshStatusFail:(PollRefreshStatusFail)pollRefreshStatusFail {
    
    __weak typeof(self) weak_self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.waitSecond * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.dataTask = [ZLHTTPManager POST:url
                                   parameters:params
                                jsonModelName:jsonModelClass
                                      success:^(ZLBaseModel *responseObject) {
                                          __strong typeof(weak_self) strong_self = weak_self;
                                          BOOL forceReturn = NO;
                                          strong_self.refreshStatusCount += 1;
                                          if (pollRefreshStatusSuccess) {
                                              forceReturn = pollRefreshStatusSuccess(responseObject, strong_self.refreshStatusCount);
                                          }
                                          
                                          if (!forceReturn && self.refreshStatusCount < self.retryCount) {
                                              
                                              [strong_self loadRequest:url
                                                                params:params
                                                        jsonModelClass:jsonModelClass
                                              pollRefreshStatusSuccess:pollRefreshStatusSuccess
                                                 pollRefreshStatusFail:pollRefreshStatusFail];
                                              return;
                                          }
                                          
                                          if (strong_self.pollRefreshStatusCompletion) {
                                              strong_self.pollRefreshStatusCompletion(responseObject, strong_self.retryCount, nil);
                                          }
                                          
                                          if ([strong_self.delegate respondsToSelector:@selector(ZLNetPollRefreshStatusDidFinish:error:)]) {
                                              [strong_self.delegate ZLNetPollRefreshStatusDidFinish:self error:nil];
                                          }
                                      } failure:^(ZLBaseModel *error) {
                                          __strong typeof(weak_self) strong_self = weak_self;
                                          BOOL forceReturn = NO;
                                          strong_self.refreshStatusCount += 1;
                                          if (pollRefreshStatusFail) {
                                              forceReturn = pollRefreshStatusFail(error, strong_self.refreshStatusCount);
                                          }
                                          
                                          if (!forceReturn && strong_self.refreshStatusCount < strong_self.retryCount) {
                                              
                                              [strong_self loadRequest:url
                                                                params:params
                                                        jsonModelClass:jsonModelClass
                                              pollRefreshStatusSuccess:pollRefreshStatusSuccess
                                                 pollRefreshStatusFail:pollRefreshStatusFail];
                                              return;
                                          }
                                          
                                          if (strong_self.pollRefreshStatusCompletion) {
                                              strong_self.pollRefreshStatusCompletion(nil, strong_self.retryCount, error);
                                          }
                                          
                                          if ([strong_self.delegate respondsToSelector:@selector(ZLNetPollRefreshStatusDidFinish:error:)]) {
                                              [strong_self.delegate ZLNetPollRefreshStatusDidFinish:self error:error];
                                          }
                                      }];
    });
}

- (BOOL)isValid {
    if (self.url &&
        self.pollRefreshStatusSuccess &&
        self.pollRefreshStatusFail) {
        return YES;
    }
    return NO;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}
@end


