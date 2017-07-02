//
//  ApiResult.h
//  NovaiOS
//
//  Created by Jackey on 16/3/13.
//  Copyright © 2016年 hecq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApiError.h"

@interface ApiResult : NSObject

@property (nonatomic, assign) BOOL success;
@property (nonatomic, strong) NSObject *data;
@property (nonatomic, strong) ApiError *error;

-(instancetype)init;

@end
