//
//  ApiResult.m
//  NovaiOS
//
//  Created by hecq on 16/3/13.
//  Copyright © 2016年 hecq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApiResult.h"

@implementation ApiResult

-(instancetype)init{
    self.error = [[ApiError alloc]init];
    return self;
}

@end