//
//  NVNetworking.m
//  NVNetworking
//
//  Created by Jackey on 2017/5/26.
//  Copyright © 2017年 com.zhouxi. All rights reserved.
//

#import "NVNetworking.h"
#import "DIctionaryToString.h"
#import "YYCache.h"

@implementation UploadParam

@end

@implementation FileUploadParam

@end
@interface NVNetworking ()


@property (nonatomic, strong) NSString              *baseUrl;

@property (nonatomic, assign) BOOL                  authorizationRequired;

@property (nonatomic, assign) NSString              *accessToken;

@property (nonatomic, assign) NVNetworkStatus       netStatus;

@property (nonatomic, strong) NSMutableArray<NSURLSessionTask *> *allTasks;

@property (nonatomic, strong) NSMutableArray<NSURLSessionTask *> *uploadTasks;

@property (nonatomic, assign) __block   BOOL        stopUpload;

@property (nonatomic, strong) YYCache               *cache;

@end

@implementation NVNetworking

static NVNetworking *_instance = nil;

+ (instancetype)shareInstance {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _instance = [[super allocWithZone:NULL] init];
        
        _instance.baseUrl               = @"";
        _instance.authorizationRequired = false;
        _instance.accessToken           = @"";
        _instance.allTasks              = [@[] mutableCopy];
        
        _instance.cache                 = [[YYCache alloc] initWithName:@"NVCACHE"];
    });
    
    return _instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    
    return [NVNetworking shareInstance];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    
    return [NVNetworking shareInstance];
}

- (NSInteger)timeout {
    
    if (!_timeout) {
        
        _timeout = 15;
    }
    
    return _timeout;
}

- (void)setBaseUrl:(NSString *)strOfURL {
    
    _baseUrl = [NSString stringWithFormat:@"%@", strOfURL];
}

- (void)setAuthorizationRequired:(BOOL)isRequired {
    
    _authorizationRequired = isRequired;
}

- (void)setAccessToken:(NSString *)accessToken {
    
    _accessToken = [NSString stringWithFormat:@"%@", accessToken];
}

- (ApiResult *)getNetworkFailResult {
    
    ApiResult *result = [[ApiResult alloc] init];
    
    result.success       = false;
    result.error.message = @"Network Error";
    result.error.code    = 9;
    result.data          = nil;
    
    return result;
}

- (NVNetworkStatus)getNetworkStatus {
    
    return _netStatus;
}

- (NSString *)getAccessToken {
    
    return _accessToken;
}

- (void)cancelUploadFile {
    
    _stopUpload = true;
    
    for (NSURLSessionTask *task in _uploadTasks) {
        
        [task cancel];
        
        [_uploadTasks removeObject:task];
        [_allTasks removeObject:task];
    }
}

- (void)startMonitorNetworkWithBlock:(NetStatusCallback)block {
    
    AFNetworkReachabilityManager *networkManager = [AFNetworkReachabilityManager sharedManager];
    
    [networkManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                _netStatus = kNoNetwork;
                if (block) {
                    
                    block(_netStatus);
                }
                break;
                
            case AFNetworkReachabilityStatusNotReachable:
                _netStatus = kNoNetwork;
                if (block) {
                    
                    block(_netStatus);
                }
                break;
                
            case AFNetworkReachabilityStatusReachableViaWWAN:
                _netStatus = k3GNetwork;
                if (block) {
                    
                    block(_netStatus);
                }
                break;
                
            case AFNetworkReachabilityStatusReachableViaWiFi:
                _netStatus = kWiFiNetwork;
                if (block) {
                    
                    block(_netStatus);
                }
                break;
            default:
                break;
        }
    }];
    
    [networkManager startMonitoring];
}

- (void)setHeaderOfAFManager:(AFHTTPSessionManager *)manager dict:(NSDictionary *)header {
    
    if (header) {
        
        //得到词典中所有KEY值
        NSEnumerator * enumeratorKey = [header keyEnumerator];
        
        //快速枚举遍历所有KEY的值
        for (NSObject *object in enumeratorKey) {
            NSString *key = (NSString *)object;
            NSObject *keyValueObject = [header objectForKey:key];
            NSString *keyValue =(NSString *)keyValueObject;
            
            [manager.requestSerializer setValue:keyValue forHTTPHeaderField:key];
        }
    }
}

- (void)cancelAllTask {
    
    if (_allTasks.count > 0) {
        
        for (NSURLSessionTask *dataTask in _allTasks) {
            
            [dataTask cancel];
        }
        
        //清空任务列表
        [_allTasks removeAllObjects];
    }
}

- (void)cancelTaskWithApi:(NSString *)api {
    
    if (_allTasks.count > 0) {
        
        for (NSURLSessionTask *dataTask in _allTasks) {
            
            if ([dataTask.currentRequest.URL.absoluteString hasSuffix:api]) {
                
                [dataTask cancel];
                
                //将已经取消的任务从任务列表中移除
                [_allTasks removeObject:dataTask];
                
                //找到一个就停止
                //break;
            }
        }
    }
}

- (NSMutableArray<NSURLSessionTask *> *)getAllTask {
    
    return _allTasks;
}

- (void)removeCompleteTask:(NSURLSessionTask *)task {
    
    if ([_allTasks containsObject:task]) {
        
        [_allTasks removeObject:task];
    }
}

- (void)get:(NSString *)api
            parameters:(id)parameters
                progress:(ProgressCallback)progresss
                    callback:(NetworkCallback)callback {
    
    NSString *cacheKey = api;
    
    if (parameters) {
        
        NSDictionary *param = [parameters mj_keyValues];
        NSString *paramStr  = [DIctionaryToString translateDictionaryToString:param];
        cacheKey            = [api stringByAppendingString:paramStr];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                         @"application/json",
                                                         @"text/json",
                                                         @"text/javascript",
                                                         @"text/html",
                                                         @"application/x-www-form-urlencoded; charset=UTF-8",
                                                         @"text/plain",
                                                         @"image/*",
                                                         nil];

    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];

    }
    
    manager.requestSerializer.timeoutInterval = _timeout;
    
    NSDictionary *paramKeyValues = [parameters mj_keyValues];
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];

    __block NSURLSessionDataTask *dataTask = \
    [manager GET:url parameters:paramKeyValues
        progress:^(NSProgress * _Nonnull downloadProgress) {
            
            if (progresss) {
                
                progresss(downloadProgress);
            }
        }
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             
             [_cache setObject:responseObject forKey:cacheKey];
             [self removeCompleteTask:dataTask];
             if (callback) {
                 
                 ApiResult *result = [ApiResult mj_objectWithKeyValues:responseObject];
                 callback(result, responseObject);
             }
             
         } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

             [self removeCompleteTask:dataTask];
             
             ApiResult *result = [self getNetworkFailResult];
             if (error.code == -999) {
                 
                 result.error.code = (int)error.code;
                 result.error.message = @"Canceled";
             }
             callback(result, error);
         }];
    
    [_allTasks addObject:dataTask];

}

- (void)get:(NSString *)api
            parameters:(id)parameters
                cachePolicy:(NVCachePolicy)cachePolicy
                    progress:(ProgressCallback)progresss
                        callback:(NetworkCallback)callback {
    
    NSString *cacheKey = api;
    
    if (parameters) {
        
        NSDictionary *param = [parameters mj_keyValues];
        NSString *paramStr  = [DIctionaryToString translateDictionaryToString:param];
        cacheKey            = [api stringByAppendingString:paramStr];
    }
    
    id object = [_cache objectForKey:cacheKey];
    
    switch (cachePolicy) {
        case kReturnCacheDataThenLoad: {
            
            if (object && callback) {
                
                ApiResult *result = [ApiResult mj_objectWithKeyValues:object];
                callback(result, object);
            }
            break;
        }
        case kReloadIgnoringLocalCacheData:
            
            break;
            
        case kReturnCacheDataNotLoad: {
            
            if (object && callback) {
                
                ApiResult *result = [ApiResult mj_objectWithKeyValues:object];
                callback(result, object);
            }
            return;
        }
            
        case kReturnCacheDataElseLoad: {
            
            if (object && callback) {
                
                ApiResult *result = [ApiResult mj_objectWithKeyValues:object];
                callback(result, object);
                return;
            }
            break;
        }
        default:
            break;
    }
    
    [self get:api parameters:parameters progress:progresss callback:callback];
}

- (NSURLSessionTask *)nv_get:(NSString *)api
                        parameters:(id)parameters
                            progress:(ProgressCallback)progresss
                                callback:(NetworkCallback)callback {
    
    NSString *cacheKey = api;
    
    if (parameters) {
        
        NSDictionary *param = [parameters mj_keyValues];
        NSString *paramStr  = [DIctionaryToString translateDictionaryToString:param];
        cacheKey            = [api stringByAppendingString:paramStr];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                         @"application/json",
                                                         @"text/json",
                                                         @"text/javascript",
                                                         @"text/html",
                                                         @"application/x-www-form-urlencoded; charset=UTF-8",
                                                         @"text/plain",
                                                         @"image/*",
                                                         nil];
    
    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    manager.requestSerializer.timeoutInterval = _timeout;
    
    NSDictionary *paramKeyValues = [parameters mj_keyValues];
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    __block NSURLSessionDataTask *dataTask = \
    [manager GET:url parameters:paramKeyValues
        progress:^(NSProgress * _Nonnull downloadProgress) {
            
            if (progresss) {
                
                progresss(downloadProgress);
            }
        }
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             
             [self removeCompleteTask:dataTask];
             [_cache setObject:responseObject forKey:cacheKey];
             if (callback) {
                 
                 ApiResult *result = [ApiResult mj_objectWithKeyValues:responseObject];
                 callback(result, responseObject);
             }
             
         } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             
             [self removeCompleteTask:dataTask];
             
             ApiResult *result = [self getNetworkFailResult];
             if (error.code == -999) {
                 
                 result.error.code = (int)error.code;
                 result.error.message = @"Canceled";
             }
             callback(result, error);
         }];
    
    [_allTasks addObject:dataTask];
    
    return dataTask;

}

- (NSURLSessionTask *)nv_get:(NSString *)api
                        parameters:(id)parameters
                            cachePolicy:(NVCachePolicy)cachePolicy
                                progress:(ProgressCallback)progresss
                                    callback:(NetworkCallback)callback {
    
    NSString *cacheKey = api;
    
    if (parameters) {
        
        NSDictionary *param = [parameters mj_keyValues];
        NSString *paramStr  = [DIctionaryToString translateDictionaryToString:param];
        cacheKey            = [api stringByAppendingString:paramStr];
    }

    id object = [_cache objectForKey:cacheKey];
    
    switch (cachePolicy) {
        case kReturnCacheDataThenLoad: {
            
            if (object && callback) {
                
                ApiResult *result = [ApiResult mj_objectWithKeyValues:object];
                callback(result, object);
            }
            break;
        }
        case kReloadIgnoringLocalCacheData:
            
            break;
            
        case kReturnCacheDataNotLoad: {
            
            if (object && callback) {
                
                ApiResult *result = [ApiResult mj_objectWithKeyValues:object];
                callback(result, object);
            }
            return nil;
        }
            
        case kReturnCacheDataElseLoad: {
            
            if (object && callback) {
                
                ApiResult *result = [ApiResult mj_objectWithKeyValues:object];
                callback(result, object);
                return nil;
            }
            break;
        }
        default:
            break;
    }
    
    return [self nv_get:api parameters:parameters progress:progresss callback:callback];
}

- (void)get:(NSString *)api
            parameters:(id)parameters
                requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                    responseSerializer:(AFHTTPResponseSerializer *)responseSerializer
                        header:(NSDictionary *)header
                            progress:(ProgressCallback)progresss
                                callback:(NetworkCallback)callback {
    
    NSString *cacheKey = api;
    
    if (parameters) {
        
        NSDictionary *param = [parameters mj_keyValues];
        NSString *paramStr  = [DIctionaryToString translateDictionaryToString:param];
        cacheKey            = [api stringByAppendingString:paramStr];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    if (responseSerializer) {
        
        manager.responseSerializer = responseSerializer;
    } else {
        
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                             @"application/json",
                                                             @"text/json",
                                                             @"text/javascript",
                                                             @"text/html",
                                                             @"application/x-www-form-urlencoded; charset=UTF-8",
                                                             @"text/plain",
                                                             @"image/*",
                                                             nil];
    }
    
    if (requestSerializer) {
        
        manager.requestSerializer = requestSerializer;
    } else {
        
        manager.requestSerializer.timeoutInterval = _timeout;
    }
    
    [self setHeaderOfAFManager:manager dict:header];
    
    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    NSDictionary *paramKeyValues = [parameters mj_keyValues];
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    __block NSURLSessionDataTask *dataTask = \
                                        [manager GET:url parameters:paramKeyValues
                                            progress:^(NSProgress * _Nonnull downloadProgress) {
                                                
                                                if (progresss) {
                                                    
                                                    progresss(downloadProgress);
                                                }
                                            }
                                          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                              
                                              [self removeCompleteTask:dataTask];
                                              [_cache setObject:responseSerializer forKey:cacheKey];
                                              if (callback) {
                                                  
                                                  ApiResult *result = [ApiResult mj_objectWithKeyValues:responseObject];
                                                  callback(result, responseObject);
                                              }
                                              
                                          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                              
                                              [self removeCompleteTask:dataTask];
                                              
                                              ApiResult *result = [self getNetworkFailResult];
                                              if (error.code == -999) {
                                                  
                                                  result.error.code = (int)error.code;
                                                  result.error.message = @"Canceled";
                                              }
                                              callback(result, error);
                                          }];
    
    [_allTasks addObject:dataTask];
}

- (void)get:(NSString *)api
            parameters:(id)parameters
                requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                    responseSerializer:(AFHTTPResponseSerializer *)responseSerializer
                        header:(NSDictionary *)header
                            cachePolicy:(NVCachePolicy)cachePolicy
                                progress:(ProgressCallback)progresss
                                    callback:(NetworkCallback)callback {
    
    NSString *cacheKey = api;
    
    if (parameters) {
        
        NSDictionary *param = [parameters mj_keyValues];
        NSString *paramStr  = [DIctionaryToString translateDictionaryToString:param];
        cacheKey            = [api stringByAppendingString:paramStr];
    }
    
    id object = [_cache objectForKey:cacheKey];
    
    switch (cachePolicy) {
        case kReturnCacheDataThenLoad: {
            
            if (object && callback) {
                
                ApiResult *result = [ApiResult mj_objectWithKeyValues:object];
                callback(result, object);
            }
            break;
        }
        case kReloadIgnoringLocalCacheData:
            
            break;
            
        case kReturnCacheDataNotLoad: {
            
            if (object && callback) {
                
                ApiResult *result = [ApiResult mj_objectWithKeyValues:object];
                callback(result, object);
            }
            return;
        }
            
        case kReturnCacheDataElseLoad: {
            
            if (object && callback) {
                
                ApiResult *result = [ApiResult mj_objectWithKeyValues:object];
                callback(result, object);
                return;
            }
            break;
        }
        default:
            break;
    }

    [self get:api parameters:parameters requestSerializer:requestSerializer responseSerializer:responseSerializer header:header progress:progresss callback:callback];
}

- (NSURLSessionTask *)nv_get:(NSString *)api
                            parameters:(id)parameters
                                requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                    responseSerializer:(AFHTTPResponseSerializer *)responseSerializer
                                        header:(NSDictionary *)header
                                            progress:(ProgressCallback)progresss
                                                callback:(NetworkCallback)callback {
    
    NSString *cacheKey = api;
    
    if (parameters) {
        
        NSDictionary *param = [parameters mj_keyValues];
        NSString *paramStr  = [DIctionaryToString translateDictionaryToString:param];
        cacheKey            = [api stringByAppendingString:paramStr];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.responseSerializer = responseSerializer;
    manager.requestSerializer  = requestSerializer;
    
    [self setHeaderOfAFManager:manager dict:header];
    
    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    NSDictionary *paramKeyValues = [parameters mj_keyValues];
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    __block NSURLSessionDataTask *dataTask = \
                                        [manager GET:url parameters:paramKeyValues
                                            progress:^(NSProgress * _Nonnull downloadProgress) {
                                                
                                                if (progresss) {
                                                    
                                                    progresss(downloadProgress);
                                                }
                                            }
                                          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                              
                                              [self removeCompleteTask:dataTask];
                                              [_cache setObject:responseSerializer forKey:cacheKey];
                                              if (callback) {
                                                  
                                                  ApiResult *result = [ApiResult mj_objectWithKeyValues:responseObject];
                                                  callback(result, responseObject);
                                              }
                                              
                                          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                              
                                              [self removeCompleteTask:dataTask];
                                              
                                              ApiResult *result = [self getNetworkFailResult];
                                              if (error.code == -999) {
                                                  
                                                  result.error.code = (int)error.code;
                                                  result.error.message = @"Canceled";
                                              }
                                              callback(result, error);
                                          }];
    
    [_allTasks addObject:dataTask];

    return dataTask;
}

- (NSURLSessionTask *)nv_get:(NSString *)api
                        parameters:(id)parameters
                            requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                responseSerializer:(AFHTTPResponseSerializer *)responseSerializer
                                    header:(NSDictionary *)header
                                        cachePolicy:(NVCachePolicy)cachePolicy
                                            progress:(ProgressCallback)progresss
                                                callback:(NetworkCallback)callback {
    
    NSString *cacheKey = api;
    
    if (parameters) {
        
        NSDictionary *param = [parameters mj_keyValues];
        NSString *paramStr  = [DIctionaryToString translateDictionaryToString:param];
        cacheKey            = [api stringByAppendingString:paramStr];
    }
    
    id object = [_cache objectForKey:cacheKey];
    
    switch (cachePolicy) {
        case kReturnCacheDataThenLoad: {
            
            if (object && callback) {
                
                ApiResult *result = [ApiResult mj_objectWithKeyValues:object];
                callback(result, object);
            }
            break;
        }
        case kReloadIgnoringLocalCacheData:
            
            break;
            
        case kReturnCacheDataNotLoad: {
            
            if (object && callback) {
                
                ApiResult *result = [ApiResult mj_objectWithKeyValues:object];
                callback(result, object);
            }
            return nil;
        }
            
        case kReturnCacheDataElseLoad: {
            
            if (object && callback) {
                
                ApiResult *result = [ApiResult mj_objectWithKeyValues:object];
                callback(result, object);
                return nil;
            }
            break;
        }
        default:
            break;
    }
    
    return [self nv_get:api parameters:parameters requestSerializer:requestSerializer responseSerializer:responseSerializer header:header progress:progresss callback:callback];
}


- (void)post:(NSString *)api
            parameters:(id)parameters
                progress:(ProgressCallback)progresss
                    callback:(NetworkCallback)callback {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                         @"application/json",
                                                         @"text/json",
                                                         @"text/javascript",
                                                         @"text/html",
                                                         @"application/x-www-form-urlencoded; charset=UTF-8",
                                                         @"text/plain",
                                                         @"image/*",
                                                         nil];
    
    if (_authorizationRequired) {
    
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    manager.requestSerializer.timeoutInterval = _timeout;
    
    NSDictionary *paramKeyValues = [parameters mj_keyValues];
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    NSLog(@"normalpost: %@", url);
    NSLog(@"normal post 参数: %@", paramKeyValues);
    __block NSURLSessionDataTask *dataTask = \
    [manager POST:url parameters:paramKeyValues
         progress:^(NSProgress * _Nonnull uploadProgress) {
             
             if (progresss) {
                 
                 progresss(uploadProgress);
             }
         }
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              
              [self removeCompleteTask:dataTask];
              
              if (callback) {
                  
                  ApiResult *result = [ApiResult mj_objectWithKeyValues:responseObject];
                  callback(result, responseObject);
              }
          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              
              [self removeCompleteTask:dataTask];
              
              ApiResult *result = [self getNetworkFailResult];
              if (error.code == -999) {
                  
                  result.error.code = (int)error.code;
                  result.error.message = @"Canceled";
              }
              callback(result, error);
          }];
    
    [_allTasks addObject:dataTask];
}

- (NSURLSessionTask *)nv_post:(NSString *)api
                            parameters:(id)parameters
                                progress:(ProgressCallback)progresss
                                    callback:(NetworkCallback)callback {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                         @"application/json",
                                                         @"text/json",
                                                         @"text/javascript",
                                                         @"text/html",
                                                         @"application/x-www-form-urlencoded; charset=UTF-8",
                                                         @"text/plain",
                                                         @"image/*",
                                                         nil];
    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    manager.requestSerializer.timeoutInterval = _timeout;
    
    NSDictionary *paramKeyValues = [parameters mj_keyValues];
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    __block NSURLSessionDataTask *dataTask = \
    [manager POST:url parameters:paramKeyValues
         progress:^(NSProgress * _Nonnull uploadProgress) {
             
             if (progresss) {
                 
                 progresss(uploadProgress);
             }
         }
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              
              [self removeCompleteTask:dataTask];
              
              if (callback) {
                  
                  ApiResult *result = [ApiResult mj_objectWithKeyValues:responseObject];
                  callback(result, responseObject);
              }
          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              
              [self removeCompleteTask:dataTask];
              
              ApiResult *result = [self getNetworkFailResult];
              if (error.code == -999) {
                  
                  result.error.code = (int)error.code;
                  result.error.message = @"Canceled";
              }
              callback(result, error);
          }];
    
    [_allTasks addObject:dataTask];
    
    return dataTask;
}

- (void)post:(NSString *)api
            parameters:(id)parameters
                requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                    responseSerializer:(AFHTTPResponseSerializer *)responseSerializer
                        header:(NSDictionary *)header
                            progress:(ProgressCallback)progresss
                                callback:(NetworkCallback)callback {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    if (responseSerializer) {
        
        manager.responseSerializer = responseSerializer;
    } else {
        
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                             @"application/json",
                                                             @"text/json",
                                                             @"text/javascript",
                                                             @"text/html",
                                                             @"application/x-www-form-urlencoded; charset=UTF-8",
                                                             @"text/plain",
                                                             @"image/*",
                                                             nil];
    }
    
    if (requestSerializer) {
        
        manager.requestSerializer = requestSerializer;
    } else {
        
        manager.requestSerializer.timeoutInterval = _timeout;
    }
    
    [self setHeaderOfAFManager:manager dict:header];
    
    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    NSDictionary *paramKeyValues = [parameters mj_keyValues];
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    __block NSURLSessionDataTask *dataTask = \
    [manager POST:url parameters:paramKeyValues
         progress:^(NSProgress * _Nonnull uploadProgress) {
             
             if (progresss) {
                 
                 progresss(uploadProgress);
             }
         }
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              
              [self removeCompleteTask:dataTask];
              
              if (callback) {
                  
                  ApiResult *result = [ApiResult mj_objectWithKeyValues:responseObject];
                  callback(result, responseObject);
              }
          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              
              [self removeCompleteTask:dataTask];
              
              ApiResult *result = [self getNetworkFailResult];
              if (error.code == -999) {
                  
                  result.error.code = (int)error.code;
                  result.error.message = @"Canceled";
              }
              callback(result, error);
          }];
    
    [_allTasks addObject:dataTask];

}

- (NSURLSessionTask *)nv_post:(NSString *)api
                   parameters:(id)parameters
            requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
           responseSerializer:(AFHTTPResponseSerializer *)responseSerializer
                       header:(NSDictionary *)header
                     progress:(ProgressCallback)progresss
                     callback:(NetworkCallback)callback {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    if (responseSerializer) {
        
        manager.responseSerializer = responseSerializer;
    } else {
        
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                             @"application/json",
                                                             @"text/json",
                                                             @"text/javascript",
                                                             @"text/html",
                                                             @"application/x-www-form-urlencoded; charset=UTF-8",
                                                             @"text/plain",
                                                             @"image/*",
                                                             nil];
    }
    
    if (requestSerializer) {
        
        manager.requestSerializer = requestSerializer;
    } else {
        
        manager.requestSerializer.timeoutInterval = _timeout;
    }
    
    [self setHeaderOfAFManager:manager dict:header];
    
    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    NSDictionary *paramKeyValues = [parameters mj_keyValues];
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    __block NSURLSessionDataTask *dataTask = \
    [manager POST:url parameters:paramKeyValues
         progress:^(NSProgress * _Nonnull uploadProgress) {
             
             if (progresss) {
                 
                 progresss(uploadProgress);
             }
         }
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              
              [self removeCompleteTask:dataTask];
              
              if (callback) {
                  
                  ApiResult *result = [ApiResult mj_objectWithKeyValues:responseObject];
                  callback(result, responseObject);
              }
          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              
              [self removeCompleteTask:dataTask];
              
              ApiResult *result = [self getNetworkFailResult];
              if (error.code == -999) {
                  
                  result.error.code = (int)error.code;
                  result.error.message = @"Canceled";
              }
              callback(result, error);
          }];
    
    [_allTasks addObject:dataTask];
    
    return dataTask;
}

- (void)upload:(NSString *)api
            parameters:(id)parameters
                uploadParams:(NSArray<UploadParam *> *)uploadParams
                    progress:(MultiUploadProgressCallback)multiProgresss
                        callback:(MultiUploadCallback)callback {
    
    _stopUpload = false;
    
    __block NSInteger totalCount = [uploadParams count];
    __block NSInteger completeCount = 0;
    __block NSInteger failCount = 0;
    
    __block dispatch_group_t uploadGroup = dispatch_group_create();
    __block dispatch_queue_t uploadQueue = dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block NSMutableArray<dispatch_semaphore_t> *semaphores = [@[] mutableCopy];
    
    if (totalCount > 0) {
        
        for (int i = 0; i < totalCount; i ++) {
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [semaphores addObject:semaphore];
        }
        
        for (int i = 0; i < totalCount; i ++) {
            
            NVWeakSelf(self)
            dispatch_group_async(uploadGroup, uploadQueue, ^{
                
                NVStrongSelf(self)
                
                if (!_stopUpload) {
                    
                    NSLog(@"开始上传第 %i 个文件", i);
                    [self upload:api parameters:parameters uploadParam:uploadParams[i] progress:^(NSProgress *progress) {
                        if (multiProgresss) {
                            
                            multiProgresss(progress, completeCount, totalCount, failCount, false);
                        }
                    } callback:^(ApiResult *result, id responseObject) {
                        
                        if (result.success) {
                            
                            completeCount += 1;
                        } else {
                            
                            completeCount += 1;
                            failCount     += 1;
                        }
                        
                        if (multiProgresss) {
                            
                            NSProgress *pg = [NSProgress progressWithTotalUnitCount:100];
                            pg.completedUnitCount = 100;
                            multiProgresss(pg, completeCount, totalCount, failCount, true);
                        }
                        
                        dispatch_semaphore_signal(semaphores[i]);
                    }];
                    
                    NSLog(@"等待上传第 %i 个文件", i);
                    dispatch_semaphore_wait(semaphores[i], DISPATCH_TIME_FOREVER);
                    NSLog(@"第 %i 个文件上传完毕", i);
                } else {
                    
                    dispatch_semaphore_wait(semaphores[i], DISPATCH_TIME_FOREVER);
                }
                
            });
        }
    }
    
    dispatch_group_notify(uploadGroup, uploadQueue, ^{
        
        if (callback && !_stopUpload) {
            
            callback(completeCount, totalCount, failCount, true);
        }
    });
}

- (void)fileUpload:(NSString *)api
            parameters:(id)parameters
                uploadParams:(NSArray<FileUploadParam *> *)fileUploadParams
                    progress:(MultiUploadProgressCallback)multiProgress
                        callback:(MultiUploadCallback)callback {
    
    _stopUpload = false;
    
    __block NSInteger totalCount = [fileUploadParams count];
    __block NSInteger completeCount = 0;
    __block NSInteger failCount = 0;
    
    __block dispatch_group_t uploadGroup = dispatch_group_create();
    __block dispatch_queue_t uploadQueue = dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block NSMutableArray<dispatch_semaphore_t> *semaphores = [@[] mutableCopy];
    
    if (totalCount > 0) {
        
        for (int i = 0; i < totalCount; i ++) {
            
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [semaphores addObject:semaphore];
        }
        
        for (int i = 0; i < totalCount; i ++) {
            
            NVWeakSelf(self)
            dispatch_group_async(uploadGroup, uploadQueue, ^{
                
                NVStrongSelf(self)
                
                if (!_stopUpload) {
                    
                    NSLog(@"开始上传第 %i 个文件", i);
                    [self fileUpload:api parameters:parameters fileUploadParam:fileUploadParams[i] progress:^(NSProgress *progress) {
                        if (multiProgress) {
                            
                            multiProgress(progress, completeCount, totalCount, failCount, false);
                        }
                    } callback:^(ApiResult *result, id responseObject) {
                        
                        if (result.success) {
                            
                            completeCount += 1;
                        } else {
                            
                            completeCount += 1;
                            failCount     += 1;
                        }
                        
                        if (multiProgress) {
                            
                            NSProgress *pg = [NSProgress progressWithTotalUnitCount:100];
                            pg.completedUnitCount = 100;
                            multiProgress(pg, completeCount, totalCount, failCount, true);
                        }
                        
                        dispatch_semaphore_signal(semaphores[i]);
                    }];
                    
                    NSLog(@"等待上传第 %i 个文件", i);
                    dispatch_semaphore_wait(semaphores[i], DISPATCH_TIME_FOREVER);
                    NSLog(@"第 %i 个文件上传完毕", i);
                } else {
                    
                    dispatch_semaphore_wait(semaphores[i], DISPATCH_TIME_FOREVER);
                }
                
            });
        }
    }
    
    dispatch_group_notify(uploadGroup, uploadQueue, ^{
        
        if (callback && !_stopUpload) {
            
            callback(completeCount, totalCount, failCount, true);
        }
    });
}

- (void)upload:(NSString *)api
            parameters:(id)parameters
                uploadParam:(UploadParam *)uploadParam
                    progress:(ProgressCallback)progresss
                        callback:(NetworkCallback)callback {
    
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                         @"application/json",
                                                         @"text/json",
                                                         @"text/javascript",
                                                         @"text/html",
                                                         @"application/x-www-form-urlencoded; charset=UTF-8",
                                                         @"text/plain",
                                                         @"image/*",
                                                         nil];
    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    NSDictionary *paramKeyValues = [parameters mj_keyValues];
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    __block NSURLSessionDataTask *dataTask = \
    [manager POST:url parameters:paramKeyValues constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [formData appendPartWithFileData:uploadParam.data
                                    name:uploadParam.name
                                fileName:uploadParam.fileName
                                mimeType:uploadParam.mimeType];

    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (progresss) {
            
            progresss(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self removeCompleteTask:dataTask];
        uploadParam.uploaded = true;
        if (callback) {
            
            ApiResult *result = [ApiResult mj_objectWithKeyValues:responseObject];
            callback(result, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self removeCompleteTask:dataTask];
        uploadParam.uploaded = false;
        if(callback){
            ApiResult * result = [self getNetworkFailResult];
            if (error.code == -999) {
                
                result.error.code = (int)error.code;
                result.error.message = @"Canceled";
            }
            callback(result,error);
        }
    }];
    
    [_allTasks addObject:dataTask];
    [_uploadTasks addObject:dataTask];
    
}

- (void)fileUpload:(NSString *)api
            parameters:(id)parameters
                fileUploadParam:(FileUploadParam *)fileUploadParam
                    progress:(ProgressCallback)progress
                        callback:(NetworkCallback)callback {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                         @"application/json",
                                                         @"text/json",
                                                         @"text/javascript",
                                                         @"text/html",
                                                         @"application/x-www-form-urlencoded; charset=UTF-8",
                                                         @"text/plain",
                                                         @"image/*",
                                                         nil];
    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    NSDictionary *paramKeyValues = [parameters mj_keyValues];
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    __block NSURLSessionDataTask *dataTask = \
    [manager POST:url parameters:paramKeyValues constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {

        NSError *error;
        BOOL success = [formData appendPartWithFileURL:[NSURL fileURLWithPath:fileUploadParam.filePath]
                                                  name:fileUploadParam.name
                                              fileName:fileUploadParam.fileName
                                              mimeType:fileUploadParam.mimeType
                                                 error:&error];
        if (!success) {
            
            NSLog(@"appendPartWithFileURL error: %@", error);
        }

    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (progress) {
            
            progress(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self removeCompleteTask:dataTask];
        fileUploadParam.uploaded = true;
        if (callback) {
            
            ApiResult *result = [ApiResult mj_objectWithKeyValues:responseObject];
            callback(result, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self removeCompleteTask:dataTask];
        fileUploadParam.uploaded = false;
        if(callback){
            ApiResult * result = [self getNetworkFailResult];
            if (error.code == -999) {
                
                result.error.code = (int)error.code;
                result.error.message = @"Canceled";
            }
            callback(result,error);
        }
    }];
    
    [_allTasks addObject:dataTask];
    [_uploadTasks addObject:dataTask];
}


- (NSURLSessionTask *)nv_upload:(NSString *)api
                        parameters:(id)parameters
                            uploadParam:(UploadParam *)uploadParam
                                progress:(ProgressCallback)progresss
                                    callback:(NetworkCallback)callback {
    
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                         @"application/json",
                                                         @"text/json",
                                                         @"text/javascript",
                                                         @"text/html",
                                                         @"application/x-www-form-urlencoded; charset=UTF-8",
                                                         @"text/plain",
                                                         @"image/*",
                                                         nil];
    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    NSDictionary *paramKeyValues = [parameters mj_keyValues];
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    __block NSURLSessionDataTask *dataTask = \
    [manager POST:url parameters:paramKeyValues constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [formData appendPartWithFileData:uploadParam.data
                                    name:uploadParam.name
                                fileName:uploadParam.fileName
                                mimeType:uploadParam.mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (progresss) {
            
            progresss(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self removeCompleteTask:dataTask];
        uploadParam.uploaded = true;
        if (callback) {
            
            ApiResult *result = [ApiResult mj_objectWithKeyValues:responseObject];
            callback(result, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self removeCompleteTask:dataTask];
        uploadParam.uploaded = false;
        if(callback){
            ApiResult * result = [self getNetworkFailResult];
            if (error.code == -999) {
                
                result.error.code = (int)error.code;
                result.error.message = @"Canceled";
            }
            callback(result,error);
        }
    }];
    
    [_allTasks addObject:dataTask];
    [_uploadTasks addObject:dataTask];
    
    return dataTask;
}

- (NSURLSessionTask *)nv_fileUpload:(NSString *)api
                            parameters:(id)parameters
                                fileUploadParam:(FileUploadParam *)fileUploadParam
                                    progress:(ProgressCallback)progresss
                                        callback:(NetworkCallback)callback {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                         @"application/json",
                                                         @"text/json",
                                                         @"text/javascript",
                                                         @"text/html",
                                                         @"application/x-www-form-urlencoded; charset=UTF-8",
                                                         @"text/plain",
                                                         @"image/*",
                                                         nil];
    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    NSDictionary *paramKeyValues = [parameters mj_keyValues];
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    __block NSURLSessionDataTask *dataTask = \
    [manager POST:url parameters:paramKeyValues constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSError *error;
        BOOL success = [formData appendPartWithFileURL:[NSURL fileURLWithPath:fileUploadParam.filePath]
                                                  name:fileUploadParam.name
                                              fileName:fileUploadParam.fileName
                                              mimeType:fileUploadParam.mimeType
                                                 error:&error];
        if (!success) {
            
            NSLog(@"appendPartWithFileURL error: %@", error);
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (progresss) {
            
            progresss(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self removeCompleteTask:dataTask];
        fileUploadParam.uploaded = true;
        if (callback) {
            
            ApiResult *result = [ApiResult mj_objectWithKeyValues:responseObject];
            callback(result, responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self removeCompleteTask:dataTask];
        fileUploadParam.uploaded = false;
        if(callback){
            ApiResult * result = [self getNetworkFailResult];
            if (error.code == -999) {
                
                result.error.code = (int)error.code;
                result.error.message = @"Canceled";
            }
            callback(result,error);
        }
    }];
    
    [_allTasks addObject:dataTask];
    [_uploadTasks addObject:dataTask];
    
    return dataTask;
}

- (void)download:(NSString *)api
                destDirectory:(NSString *)destDirectory
                    progress:(ProgressCallback)progresss
                        callBack:(DownloadCallback)callback {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                         @"application/json",
                                                         @"text/json",
                                                         @"text/javascript",
                                                         @"text/html",
                                                         @"application/x-www-form-urlencoded; charset=UTF-8",
                                                         @"text/plain",
                                                         @"image/*",
                                                         nil];
    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    __block NSURLSessionDownloadTask *downloadTask = \
    [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        if (progresss) {
            
            progresss(downloadProgress);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        NSString *path = [destDirectory stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:path];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        [self removeCompleteTask:downloadTask];
        
        if (callback) {
            
            callback(response, filePath, error);
        }
    }];
    
    [_allTasks addObject:downloadTask];
}



- (NSURLSessionTask *)nv_download:(NSString *)api
                            destDirectory:(NSString *)destDirectory
                                progress:(ProgressCallback)progresss
                                    callBack:(DownloadCallback)callback {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                         @"application/json",
                                                         @"text/json",
                                                         @"text/javascript",
                                                         @"text/html",
                                                         @"application/x-www-form-urlencoded; charset=UTF-8",
                                                         @"text/plain",
                                                         @"image/*",
                                                         nil];
    if (_authorizationRequired) {
        
        [manager.requestSerializer setValue:_accessToken forHTTPHeaderField:@"Authentication"];
    }
    
    NSString *url = [_baseUrl stringByAppendingString:[NSString stringWithFormat:@"%@", api]];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    __block NSURLSessionDownloadTask *downloadTask = \
    [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        if (progresss) {
            
            progresss(downloadProgress);
        }
    }  destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        NSString *path = [destDirectory stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:path];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        [self removeCompleteTask:downloadTask];
        
        if (callback) {
            
            callback(response, filePath, error);
        }
    }];
    
    [_allTasks addObject:downloadTask];
    
    return downloadTask;
}

@end
