//
//  ApiError.h
//  NovaIOSFramework
//
//  Created by Jackey on 16/5/30.
//  Copyright © 2016年 castiel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApiError : NSObject

@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) int code;

@end
