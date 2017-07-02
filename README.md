#带缓存机制的网络请求

各类请求有分带缓存 , 不带缓存, 可自定义, 默认请求头和解析头等几种方式

#没有缓存机制的网络请求库

##初始化

```objective-c
//测试初始化
_nvNetworking = [NVNetworking shareInstance];

//测试设置beseUrl
[_nvNetworking setBaseUrl:@"http://xdf-new-test.novasoftware.cn/api"];

//测试设置需要授权
[_nvNetworking setAuthorizationRequired:true];

//检测网络监听
[_nvNetworking startMonitorNetworkWithBlock:^(NVNetworkStatus status) {

NSLog(@"status: %lu", status);
}];

```

##默认请求样式
```objective-c
//使用默认请求样式:

[_nvNetworking get:@"/open/ads" parameters:nil progress:^(NSProgress *downloadProgress) {

NSLog(@"进度: %f", downloadProgress.fractionCompleted);
} callback:^(ApiResult *result, id responseObject) {

if (result.success) {

NSLog(@"%@", result.data);
}

NSLog(@"请求结束后网络请求个数: %lu", (unsigned long)[[_nvNetworking getAllTask] count]);
}];

NSLog(@"请求结束前网络请求个数: %lu", (unsigned long)[[_nvNetworking getAllTask] count]);

```

##取消所有任务
```objective-c
[_nvNetworking cancelAllTask];
```

##取消特定api的请求
```objective-c
[_nvNetworking cancelTaskWithApi:@"open/ads"];
```

##带任务返回的请求Get/Post
```objective-c
NVNetworking *manager = [NVNetworking shareInstance];
_task = [manager nv_get:@"/pushMessage/GetpushMessages?phonenumber=18502329837" parameters:nil progress:nil callback:^(ApiResult *result, id responseObject) {

if (result.success) {

NSLog(@"回调: %@", result.data);
NSDictionary *dict = [result.data mj_keyValues];
NSLog(@"dict: %@", dict);
} else {

NSLog(@"失败回调: %@", responseObject);
NSLog(@"失败code: %i", result.error.code);
}
}];
```

##取消任务
```objective-c
[_task cancel];
```

##自定义请求样式
```objective-c
AFHTTPRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
AFHTTPResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];

[_nvNetworking get:@"/open/ads" parameters:nil requestSerializer:requestSerializer responseSerializer:responseSerializer header:nil progress:^(NSProgress *downloadProgress) {

NSLog(@"%f", downloadProgress.fractionCompleted);
} callback:^(ApiResult *result, id responseObject) {

NSLog(@"请求结束后网络请求个数: %lu", (unsigned long)[[_nvNetworking getAllTask] count]);
if (result.success) {

NSLog(@"%@", result.data);
}
}];
```

##网络监听
```objective-c
[_nvNetworking startMonitorNetworkWithBlock:^(NVNetworkStatus status) {

switch (status) {
case k3GNetwork:
NSLog(@"3G网");
break;

case kWiFiNetwork:
NSLog(@"wifi");
break;

case kNoNetwork:
NSLog(@"没有网");
break;
default:
break;
}
}];
```

##单个文件上传
```objective-c
UploadParam *uploadParam = [[UploadParam alloc] init];
uploadParam.data = UIImagePNGRepresentation([UIImage imageNamed:@"1.png"]);
uploadParam.name = @"1.png";
uploadParam.fileName = @"1.png";
uploadParam.mimeType = @"image/png";

NVNetworking *manager = [NVNetworking shareInstance];
[manager upload:@"/file/upload" parameters:nil uploadParam:uploadParam progress:^(NSProgress *progress) {

NSLog(@"上传进度: %f", progress.fractionCompleted);
} callback:^(ApiResult *result, id responseObject) {

NSLog(@"结果: %@", responseObject);

if (result.success) {

NSLog(@"回调: %@", result.data);
NSDictionary *dict = [result.data mj_keyValues];
NSLog(@"dict: %@", dict);
} else {

NSLog(@"失败回调: %@", responseObject);
NSLog(@"失败code: %i", result.error.code);
}
}];
```

##取消上传任务可以用
```objective-c
NVNetworking *manager = [NVNetworking shareInstance];
[manager cancelTaskWithApi:@"/file/upload"];
```

##多任务上传
```objective-c
UploadParam *uploadParam = [[UploadParam alloc] init];
uploadParam.data = UIImagePNGRepresentation([UIImage imageNamed:@"1.png"]);
uploadParam.name = @"1.png";
uploadParam.fileName = @"1.png";
uploadParam.mimeType = @"image/png";

UploadParam *uploadParam1 = [[UploadParam alloc] init];
uploadParam1.data = UIImagePNGRepresentation([UIImage imageNamed:@"1.png"]);
uploadParam1.name = @"1.png";
uploadParam1.fileName = @"1.png";
uploadParam1.mimeType = @"image/png";

NSArray *array = @[uploadParam, uploadParam1];
NVNetworking *manager = [NVNetworking shareInstance];

[manager upload:@"/file/upload" parameters:nil uploadParams:array progress:^(NSProgress *progress, NSInteger completeCount, NSInteger totalCount, NSInteger failCount, BOOL taskCompleted) {

NSLog(@"progress: %f, completeCount: %li, totalCount: %li, failCount: %li, taskCompleted: %@", progress.fractionCompleted, (long)completeCount, (long)totalCount, (long)failCount, taskCompleted ? @"YES": @"NO");
} callback:^(NSInteger completeCount, NSInteger totalCount, NSInteger failCount, BOOL taskCompleted) {

NSLog(@"completeCount: %li, totalCount: %li, failCount: %li, taskCompleted: %@", (long)completeCount, (long)totalCount, (long)failCount, taskCompleted ? @"YES": @"NO");

}];
```

##取消多任务上传
```objective-c
NVNetworking *manager = [NVNetworking shareInstance];
[manager cancelUploadFile];
```

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
```objective-c
/**
 带任务返回 进度回调 缓存策略的 自定义 get请求

 @param api api
 @param parameters object参数
 @param requestSerializer 请求样式
 @param responseSerializer 响应样式
 @param header 请求头数据(字典)
 @param cachePolicy 缓存策略
 @param progresss 进度回调
 @param callback 回调方法
 @return 本次请求的task
 */
- (NSURLSessionTask *)nv_get:(NSString *)api
                  parameters:(id)parameters
           requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
          responseSerializer:(AFHTTPResponseSerializer *)responseSerializer
                      header:(NSDictionary *)header
                 cachePolicy:(NVCachePolicy)cachePolicy
                    progress:(ProgressCallback)progresss
                    callback:(NetworkCallback)callback;
```
