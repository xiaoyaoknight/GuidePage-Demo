//
//  NSDictionary+ZLNetSerialize.h
//  Pods-ZLNetWork_Example
//
//  Created by 王泽龙 on 2019/7/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (ZLNetSerialize)

/**
 *  按 key 升序排列字典
 *
 *  @return 返回排序后数组key
 */
- (NSMutableArray *)sortDictWithAscendingKey;

/**
 *  序列化成oauth格式的签名串
 */
- (void)serializeDictToOauth1:(NSString *)signKey appendDict:(NSDictionary *)appendDict;

/**
 *  序列化成oauth格式的签名串，并支持排除某些字段
 */
- (void)serializeDictToOauth1:(NSString *)signKey appendDict:(NSDictionary *)appendDict exclude:(NSArray *)excludeKeys;

@end

NS_ASSUME_NONNULL_END
