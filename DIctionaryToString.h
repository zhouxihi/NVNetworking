//
//  DIctionaryToString.h
//  CacheDemo
//
//  Created by Jackey on 2017/6/2.
//  Copyright © 2017年 com.zhouxi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DIctionaryToString : NSObject

/**
 将NSDictionary转化为NSString

 @param dict 字典
 @return 转化后的字符串
 */
+ (NSString *)translateDictionaryToString:(NSDictionary *)dict;

@end
