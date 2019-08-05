//
//  ZLBaseModel.m
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import "ZLBaseModel.h"

@implementation ZLBaseModel

- (instancetype)initWithCode:(NSInteger)errcode errstr:(NSString *)errstr {
    self = [super init];
    if (self) {
        
        self.errcode = errcode;
        self.errstr = errstr;
    }
    return self;
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName {
    return YES;
}

- (NSError *)error {
    self.errstr = self.errstr ? : @"";
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:self.errcode userInfo:@{NSLocalizedDescriptionKey : self.errstr}];
    return error;
}

@end
