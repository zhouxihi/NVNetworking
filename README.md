#带缓存机制的网络请求

带缓存机制的网络请求包含未带缓存机制网络请求的所有功能, 使用方法也相同
用力可以参考:

[http://git.novasoftware.cn:3000/zhouxi/NVNetworking](http://git.novasoftware.cn:3000/zhouxi/NVNetworking)

##缓存策略有以下几种
```objective-c
    kReturnCacheDataThenLoad = 0,   //有缓存先返回缓存, 并同步请求
    kReloadIgnoringLocalCacheData,  //忽略缓存, 直接请求
    kReturnCacheDataElseLoad,       //有缓存就返回缓存, 没有缓存再请求
    kReturnCacheDataNotLoad         //有缓存就返回缓存, 没有缓存也不请求
```

##带缓存策略 get请求
```objective-c
/**
 带进度回调 缓存策略的 normal get请求

 @param api api
 @param parameters object参数
 @param cachePolicy 缓存策略
 @param progresss 进度回调
 @param callback 回调方法
 */
- (void)get:(NSString *)api
            parameters:(id)parameters
                cachePolicy:(NVCachePolicy)cachePolicy
                    progress:(ProgressCallback)progresss
                        callback:(NetworkCallback)callback;
```

##带缓存策略 任务返回的 get请求
```objective-c
/**
/**
 带任务返回 进度回调 缓存策略的 get请求

 @param api api
 @param parameters object参数
 @param cachePolicy 缓存策略
 @param progresss 进度回调
 @param callback 回调方法
 @return 本次请求的task
 */
- (NSURLSessionTask *)nv_get:(NSString *)api
                        parameters:(id)parameters
                            cachePolicy:(NVCachePolicy)cachePolicy
                                progress:(ProgressCallback)progresss
                                    callback:(NetworkCallback)callback;
```

##带缓存策略的 自定义get请求
```objective-c
/**
 带进度回调的 自定义 带缓存策略的 get请求

 @param api api
 @param parameters object参数
 @param requestSerializer 请求样式
 @param responseSerializer 响应样式
 @param header 请求头数据(字典)
 @param cachePolicy 缓存策略
 @param progresss 进度回调
 @param callback 回调方法
 */
- (void)get:(NSString *)api
            parameters:(id)parameters
                requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                    responseSerializer:(AFHTTPResponseSerializer *)responseSerializer
                        header:(NSDictionary *)header
                            cachePolicy:(NVCachePolicy)cachePolicy
                                progress:(ProgressCallback)progresss
                                    callback:(NetworkCallback)callback;
```

##带任务返回 缓存策略的 自定义get请求
