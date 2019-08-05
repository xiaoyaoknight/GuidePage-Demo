//
//  NSDictionary+ZLNetSerialize.m
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import "NSMutableDictionary+ZLNetSerialize.h"
#import "JSONKit.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSMutableDictionary (ZLNetSerialize)

/**
 *  按 key 升序排列字典
 *
 *  @return 返回排序后数组key
 */
- (NSMutableArray *)sortDictWithAscendingKey {
    
    NSMutableArray *numArray = [NSMutableArray arrayWithArray:self.allKeys];
    [numArray sortUsingComparator: ^NSComparisonResult (NSString *str1, NSString *str2) {
        return [str1 compare:str2];
    }];
    NSMutableDictionary *newDict = [NSMutableDictionary new];
    for (NSString *key in numArray) {
        [newDict setObject:self[key] forKey:key];
    }
    [self removeAllObjects];
    for (NSString *key in numArray) {
        [self setObject:newDict[key] forKey:key];
    }
    return numArray;
}

/**
 *  序列化成oauth格式的签名串
 */
- (void)serializeDictToOauth1:(NSString *)signKey appendDict:(NSDictionary *)appendDict {
    [self serializeDictToOauth1:signKey appendDict:appendDict exclude:nil];
}

/**
 *  序列化成oauth格式的签名串，并支持排除某些字段
 */
- (void)serializeDictToOauth1:(NSString *)signKey appendDict:(NSDictionary *)appendDict exclude:(NSArray *)excludeKeys {
    
    if (appendDict) {
        [self addEntriesFromDictionary:appendDict];
    }
    
    NSMutableArray *allKeys = [self sortDictWithAscendingKey];
    // 移除掉一些不参加sign的参数
    if (excludeKeys) {
        for(id key in excludeKeys) {
            [allKeys removeObject:key];
        }
    }
    
    NSMutableArray *urlStrings = [NSMutableArray new];
    for (int i = 0; i < allKeys.count; i++) {
        NSString *key = allKeys[i];
        NSString *value;
        
        // 如果超过二维并且是字典的话,将字典转换成 json
        if ([self[key] isKindOfClass:[NSDictionary class]] || [self[key] isKindOfClass:[NSArray class]]) {
            
            value = [self[key] JSONString];
            [self setObject:value forKey:key];
            
        } else {
            
            value = self[key];
        }
        
        
        [urlStrings addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }
    NSString *strings = [urlStrings componentsJoinedByString:@"&"];
    NSString *sign = [NSString stringWithFormat:@"%@%@%@", signKey,strings, signKey];
    NSString *md5String = [self md5HexDigest:sign];
    [self setObject:md5String forKey:@"sign"];
}

- (NSString *)md5HexDigest:(NSString *)string {
    const char *original_str = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, (CC_LONG)strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [hash lowercaseString];
}
@end

