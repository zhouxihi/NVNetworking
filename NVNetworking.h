//
//  NVNetworking.h
//  NVNetworking
//
//  Created by Jackey on 2017/5/26.
//  Copyright © 2017年 com.zhouxi. All rights reserved.
//
//  需要添加sqlite3.lib

#import <Foundation/Foundation.h>

#import "AFNetworking.h"
#import "MJExtension.h"
#import "ApiResult.h"

typedef enum : NSUInteger {
    
    kReturnCacheDataThenLoad = 0,   //有缓存先返回缓存, 并同步请求
    kReloadIgnoringLocalCacheData,  //忽略缓存, 直接请求
    kReturnCacheDataElseLoad,       //有缓存就返回缓存, 没有缓存再请求
    kReturnCacheDataNotLoad         //有缓存就返回缓存, 没有缓存也不请求
} NVCachePolicy;

#define NVWeakSelf(type)  __weak typeof(type) weak##type = type;
#define NVStrongSelf(type)  __strong typeof(type) type = weak##type;

typedef enum : NSUInteger {
    
    kNoNetwork = 0,
    k3GNetwork,
    kWiFiNetwork,
    
} NVNetworkStatus;

typedef void(^NetworkCallback)(ApiResult *result, id responseObject);
typedef void(^NetStatusCallback)(NVNetworkStatus status);
typedef void(^ProgressCallback)(NSProgress *progress);
typedef void(^DownloadCallback)(NSURLResponse *response, NSURL *filePath, NSError *error);
typedef void(^MultiUploadProgressCallback)(NSProgress *progress, NSInteger completeCount, NSInteger totalCount, NSInteger failCount, BOOL taskCompleted);
typedef void(^MultiUploadCallback)(NSInteger completeCount, NSInteger totalCount, NSInteger failCount, BOOL taskCompleted);

/**
 通过NSData上传
 */
@interface UploadParam : NSObject

/**
 待上传的二进制数据
 */
@property (nonatomic, strong) NSData *data;

/**
 文件名称
 */
@property (nonatomic, copy) NSString *name;

/**
 保存在服务器上的文件名称
 */
@property (nonatomic, copy) NSString *fileName;

/**
 文件的类型(image/png, image/jpg等等)
 */
@property (nonatomic, copy) NSString *mimeType;

/**
 是否成功上传
 */
@property (nonatomic, assign) BOOL    uploaded;

@end

/**
 通过文件地址上传
 */
@interface FileUploadParam : NSObject

/**
 待上传的文件地址
 */
@property (nonatomic, strong) NSString *filePath;

/**
 文件名称
 */
@property (nonatomic, copy) NSString *name;

/**
 保存在服务器上的文件名称
 */
@property (nonatomic, copy) NSString *fileName;

/**
 文件的类型(image/png, image/jpg等等)
 */
@property (nonatomic, copy) NSString *mimeType;

/**
 是否成功上传
 */
@property (nonatomic, assign) BOOL    uploaded;

@end

@interface NVNetworking : NSObject

/**
 get/post请求的最大响应延迟, 默认为15s
 如果为自定义请求, 需要在传入的requestSerializer中设置, 默认时间为30s
 */

@property (nonatomic, assign) NSInteger timeout;

/**
 创建单例方法
 
 @return 单例
 */
+ (instancetype)shareInstance;

/**
 设置服务器基地址

 @param strOfURL 服务器地址
 */
- (void)setBaseUrl:(NSString *)strOfURL;

/**
 设置accessToken

 @param accessToken token
 */
- (void)setAccessToken:(NSString *)accessToken;

/**
 设置网络请求是否需要授权

 @param isRequired 是否需要授权
 */
- (void)setAuthorizationRequired:(BOOL)isRequired;

/**
 获取accessToken

 @return accessToken
 */
- (NSString *)getAccessToken;

/**
 开启网络监听

 @param block 网络监听网络监听block
 */
- (void)startMonitorNetworkWithBlock:(NetStatusCallback)block;

/**
 获取网络状态

 @return 网络状态
 */
- (NVNetworkStatus)getNetworkStatus;

/**
 取消所有的网络请求
 */
- (void)cancelAllTask;

/**
 取消知道api的请求

 @param api api地址
 */
- (void)cancelTaskWithApi:(NSString *)api;

/**
 获取所有正在进行中的任务

 @return 所有进行中任务列表
 */
- (NSMutableArray<NSURLSessionTask *> *)getAllTask;

/**
 停止上传文件
 */
- (void)cancelUploadFile;

/**
 带进度回调的 normal get请求

 @param api api
 @param parameters object参数
 @param progresss 进度回调
 @param callback 回调方法
 */
- (void)get:(NSString *)api
        parameters:(id)parameters
            progress:(ProgressCallback)progresss
                callback:(NetworkCallback)callback;

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

/**
 带任务返回 进度回调的 get请求

 @param api api
 @param parameters object参数
 @param progresss 进度回调
 @param callback 回调方法
 @return 本次请求的task
 */
- (NSURLSessionTask *)nv_get:(NSString *)api
                        parameters:(id)parameters
                            progress:(ProgressCallback)progresss
                                callback:(NetworkCallback)callback;

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

/**
 带进度回调的 自定义 get请求

 @param api api
 @param parameters object参数
 @param requestSerializer 请求样式
 @param responseSerializer 响应样式
 @param header 请求头数据(字典)
 @param progresss 进度回调
 @param callback 回调方法
 */
- (void)get:(NSString *)api
            parameters:(id)parameters
                requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                    responseSerializer:(AFHTTPResponseSerializer *)responseSerializer
                        header:(NSDictionary *)header
                            progress:(ProgressCallback)progresss
                                callback:(NetworkCallback)callback;

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


/**
 带任务返回 进度回调的 自定义 get请求

 @param api api
 @param parameters object参数
 @param requestSerializer 请求样式
 @param responseSerializer 响应样式
 @param header 请求头数据(字典)
 @param progresss 进度回调
 @param callback 回调方法
 @return 本次请求的task
 */
- (NSURLSessionTask *)nv_get:(NSString *)api
                  parameters:(id)parameters
           requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
          responseSerializer:(AFHTTPResponseSerializer *)responseSerializer
                      header:(NSDictionary *)header
                    progress:(ProgressCallback)progresss
                    callback:(NetworkCallback)callback;

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

/**
 带进度回调的 normal post请求

 @param api api
 @param parameters object参数
 @param progresss 进度回调
 @param callback 回调方法
 */
- (void)post:(NSString *)api
            parameters:(id)parameters
                progress:(ProgressCallback)progresss
                    callback:(NetworkCallback)callback;

/**
 带任务返回 进度回调的 post请求

 @param api api
 @param parameters object参数
 @param progresss 进度回调
 @param callback 回调方法
 @return 本次请求的task
 */
- (NSURLSessionTask *)nv_post:(NSString *)api
                   parameters:(id)parameters
                     progress:(ProgressCallback)progresss
                     callback:(NetworkCallback)callback;

/**
带进度回调 自定义 post请求

 @param api api
 @param parameters object参数
 @param requestSerializer 请求样式
 @param responseSerializer 响应样式
 @param header 请求头数据(字典)
 @param progresss 进度回调
 @param callback 回调方法
 */
- (void)post:(NSString *)api
            parameters:(id)parameters
                requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                    responseSerializer:(AFHTTPResponseSerializer *)responseSerializer
                        header:(NSDictionary *)header
                            progress:(ProgressCallback)progresss
                                callback:(NetworkCallback)callback;


/**
 带任务返回 进度回调 自定义 post请求

 @param api api
 @param parameters object参数
 @param requestSerializer 请求样式
 @param responseSerializer 响应样式
 @param header 请求头数据(字典)
 @param progresss 进度回调
 @param callback 回调方法
 @return 本次请求的task
 */
- (NSURLSessionTask *)nv_post:(NSString *)api
                   parameters:(id)parameters
            requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
           responseSerializer:(AFHTTPResponseSerializer *)responseSerializer
                       header:(NSDictionary *)header
                     progress:(ProgressCallback)progresss
                     callback:(NetworkCallback)callback;

/**
 带上传进度 上传文件 (NSData)

 @param api api
 @param parameters object参数
 @param uploadParam 上传对象uploadParam
 @param progresss 进度回调
 @param callback 回调方法
 */
- (void)upload:(NSString *)api
            parameters:(id)parameters
                uploadParam:(UploadParam *)uploadParam
                    progress:(ProgressCallback)progresss
                        callback:(NetworkCallback)callback;

/**
 带上传进度 上传文件 (File Path)

 @param api api
 @param parameters object参数
 @param fileUploadParam 上传对象uploadParam
 @param progress 进度回调
 @param callback 回调方法
 */
- (void)fileUpload:(NSString *)api
            parameters:(id)parameters
                fileUploadParam:(FileUploadParam *)fileUploadParam
                    progress:(ProgressCallback)progress
                        callback:(NetworkCallback)callback;

/**
 多文件上传, 带上传进度 (NSData)

 @param api api
 @param parameters object参数
 @param uploadParams 上传对象列表
 @param multiProgresss 多文件上传进度回调
 @param callback 回调方法
 */
- (void)upload:(NSString *)api
            parameters:(id)parameters
                uploadParams:(NSArray<UploadParam *> *)uploadParams
                    progress:(MultiUploadProgressCallback)multiProgresss
                        callback:(MultiUploadCallback)callback;

/**
 多文件上传, 带上传进度 (File Path)

 @param api api
 @param parameters object参数
 @param fileUploadParams 上传对象列表
 @param multiProgress 多文件上传进度回调
 @param callback 回调方法
 */
- (void)fileUpload:(NSString *)api
            parameters:(id)parameters
                uploadParams:(NSArray<FileUploadParam *> *)fileUploadParams
                    progress:(MultiUploadProgressCallback)multiProgress
                        callback:(MultiUploadCallback)callback;


/**
 带任务返回 下载进度 上传文件 (NSData)

 @param api api
 @param parameters object参数
 @param uploadParam 上传对象uploadParam
 @param progresss 上传进度回调
 @param callback 回调方法
 @return 本次请求的task
 */
- (NSURLSessionTask *)nv_upload:(NSString *)api
                            parameters:(id)parameters
                                uploadParam:(UploadParam *)uploadParam
                                    progress:(ProgressCallback)progresss
                                        callback:(NetworkCallback)callback;

/**
 带任务返回 下载进度 上传文件 (File Path)
 
 @param api api
 @param parameters object参数
 @param fileUploadParam 上传对象uploadParam
 @param progresss 上传进度回调
 @param callback 回调方法
 @return 本次请求的task
 */
- (NSURLSessionTask *)nv_fileUpload:(NSString *)api
                         parameters:(id)parameters
                            fileUploadParam:(FileUploadParam *)fileUploadParam
                                progress:(ProgressCallback)progresss
                                    callback:(NetworkCallback)callback;

/**
 下载文件

 @param api api
 @param destDirectory 存储路径
 @param progresss 下载进度回调
 @param callback 回调方法
 */
- (void)download:(NSString *)api
            destDirectory:(NSString *)destDirectory
                progress:(ProgressCallback)progresss
                    callBack:(DownloadCallback)callback;

/**
 带任务返回的 带下载进度的 下载文件

 @param api api
 @param destDirectory 存储路径
 @param progresss 下载进度回调
 @param callback 回调方法
 @return 本次请求的task
 */
- (NSURLSessionTask *)nv_download:(NSString *)api
                    destDirectory:(NSString *)destDirectory
                         progress:(ProgressCallback)progresss
                         callBack:(DownloadCallback)callback;

@end
