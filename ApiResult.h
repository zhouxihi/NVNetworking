//
//  ApiResult.h
//  NovaiOS
//
//  Created by hecq on 16/3/13.
//  Copyright © 2016年 hecq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApiError.h"

@interface ApiResult : NSObject

    
    @property BOOL success;
    @property  NSObject * data;
    @property ApiError * error;
    

-(instancetype)init;

@end