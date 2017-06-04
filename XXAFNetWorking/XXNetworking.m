//
//  XXNetworking.m
//  XXAFNetWorking
//
//  Created by Beelin on 2017/6/4.
//  Copyright © 2017年 Beelin. All rights reserved.
//

#import "XXNetworking.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

#import "XXCacheManager.h"

static NSMutableArray *_allSessionTask;
static AFHTTPSessionManager *_sessionManager;
@implementation XXNetworking

#pragma mark - 初始化AFHTTPSessionManager相关属性
/**
 开始监测网络状态
 */
+ (void)load {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}
/**
 *  所有的HTTP请求共享一个AFHTTPSessionManager
 */
+ (void)initialize {
    _sessionManager = [AFHTTPSessionManager manager];
    // 设置请求的超时时间
    _sessionManager.requestSerializer.timeoutInterval = 20.f;
    // 设置服务器返回结果的类型:JSON (AFJSONResponseSerializer,AFHTTPResponseSerializer)
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    // 打开状态栏的等待菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}

#pragma mark - 开始监听网络
+ (void)networkStatusWithBlock:(XXNetworkStatus)networkStatus {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    networkStatus ? networkStatus(XXNetworkStatusUnknown) : nil;
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    networkStatus ? networkStatus(XXNetworkStatusNotReachable) : nil;
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    networkStatus ? networkStatus(XXNetworkStatusReachableViaWWAN) : nil;
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    networkStatus ? networkStatus(XXNetworkStatusReachableViaWiFi) : nil;
                    break;
            }
        }];
    });
}

+ (BOOL)isNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

+ (BOOL)isWWANNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

+ (BOOL)isWiFiNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

/**
 存储着所有的请求task数组
 */
+ (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [[NSMutableArray alloc] init];
    }
    return _allSessionTask;
}

+ (void)cancelAllRequest {
    // 锁操作
    @synchronized(self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)URL {
    if (!URL) return;
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}
#pragma mark - get
+ (XXURLSessionTask *)getWithUrl:(NSString *)url
                  refreshRequest:(BOOL)refresh
                           cache:(BOOL)cache
                          params:(NSDictionary *)params
                   progressBlock:(XXGetProgress)progressBlock
                    successBlock:(XXResponseSuccessBlock)successBlock
                       failBlock:(XXResponseFailBlock)failBlock
{
    if (cache) {
        id responseObj = [[XXCacheManager shareManager] getCacheResponseObjectWithRequestUrl:url params:params];
        if (responseObj) !successBlock ?: successBlock(responseObj);
    }
    
    XXURLSessionTask *sessionTask = [_sessionManager GET:url
                parameters:params
                  progress:^(NSProgress * _Nonnull downloadProgress) {
                      if (progressBlock) progressBlock(downloadProgress.completedUnitCount,
                                                       downloadProgress.totalUnitCount);
                      
                  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if (successBlock) successBlock(responseObject);
                      
                      if (cache) {
                          [[XXCacheManager shareManager] clearLRUCache];//清除最近最少使用缓存
                          [[XXCacheManager shareManager] cacheResponseObject:responseObject requestUrl:url params:params];
                      }
                      
                      [[self allSessionTask] removeObject:task];
                      
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      if (failBlock) failBlock(error);
                      [[self allSessionTask] removeObject:task];
                      
                  }];
    // 添加sessionTask到数组
    !sessionTask ?: [[self allSessionTask] addObject:sessionTask];
    return sessionTask;
    
}

#pragma mark - post
+ (XXURLSessionTask *)postWithUrl:(NSString *)url
                   refreshRequest:(BOOL)refresh
                            cache:(BOOL)cache
                           params:(NSDictionary *)params
                    progressBlock:(XXPostProgress)progressBlock
                     successBlock:(XXResponseSuccessBlock)successBlock
                        failBlock:(XXResponseFailBlock)failBlock
{
    if (cache) {
        id responseObj = [[XXCacheManager shareManager] getCacheResponseObjectWithRequestUrl:url params:params];
        if (responseObj) !successBlock ?: successBlock(responseObj);
    }
     XXURLSessionTask *sessionTask = [_sessionManager POST:url
                 parameters:params
                   progress:^(NSProgress * _Nonnull uploadProgress) {
                       if (progressBlock) progressBlock(uploadProgress.completedUnitCount,
                                                        uploadProgress.totalUnitCount);
                       
                   } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                       if (successBlock) successBlock(responseObject);
                       
                       if (cache) {
                           [[XXCacheManager shareManager] clearLRUCache];//清除最近最少使用缓存
                            [[XXCacheManager shareManager] cacheResponseObject:responseObject requestUrl:url params:params];
                       }
                       
                       if ([[self allSessionTask] containsObject:task]) {
                           [[self allSessionTask] removeObject:task];
                       }
                       
                   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                       if (failBlock) failBlock(error);
                       [[self allSessionTask] removeObject:task];
                       
                   }];
    // 添加sessionTask到数组
    !sessionTask ?: [[self allSessionTask] addObject:sessionTask];
    return sessionTask;
}

#pragma mark - 单/多图片上传
+ (XXURLSessionTask *)uploadImagesWithURL:(NSString *)URL
                               parameters:(id)parameters
                                     name:(NSString *)name
                                   images:(NSArray<UIImage *> *)images
                                fileNames:(NSArray<NSString *> *)fileNames
                               imageScale:(CGFloat)imageScale
                                imageType:(NSString *)imageType
                                 progress:(XXUploadProgressBlock)progressBlock
                                  success:(XXResponseSuccessBlock)successBlock
                                  failure:(XXResponseFailBlock)failBlock
{
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (NSUInteger i = 0; i < images.count; i++) {
            // 图片经过等比压缩后得到的二进制文件
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.f);
            // 默认图片的文件名, 若fileNames为nil就使用
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *imageFileName = [NSString stringWithFormat:@"%@%ld.%@",str,i,imageType?:@"jpg"];
            
            [formData appendPartWithFileData:imageData
                                        name:name
                                    fileName:fileNames ? [NSString stringWithFormat:@"%@.%@",fileNames[i],imageType?:@"jpg"] : imageFileName
                                    mimeType:[NSString stringWithFormat:@"image/%@",imageType ?: @"jpg"]];
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progressBlock) progressBlock(uploadProgress.completedUnitCount,
                                             uploadProgress.totalUnitCount);
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self allSessionTask] removeObject:task];
        successBlock ? successBlock(responseObject) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allSessionTask] removeObject:task];
        failBlock ? failBlock(error) : nil;
    }];
    
    // 添加sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
    
    return sessionTask;

}

#pragma mark - 文件上传
+ (XXURLSessionTask *)uploadFileWithUrl:(NSString *)url
                               fileData:(NSData *)data
                                   type:(NSString *)type
                                   name:(NSString *)name
                               mimeType:(NSString *)mimeType
                          progressBlock:(XXUploadProgressBlock)progressBlock
                           successBlock:(XXResponseSuccessBlock)successBlock
                              failBlock:(XXResponseFailBlock)failBlock
{
    XXURLSessionTask *sessionTask = [_sessionManager POST:url
                 parameters:nil
  constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
      NSString *fileName = nil;
      
      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      formatter.dateFormat = @"yyyyMMddHHmmss";
      
      NSString *day = [formatter stringFromDate:[NSDate date]];
      
      fileName = [NSString stringWithFormat:@"%@.%@",day,type];
      
      [formData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
      
  } progress:^(NSProgress * _Nonnull uploadProgress) {
      if (progressBlock) progressBlock (uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
      
  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
      if (successBlock) successBlock(responseObject);
      [[self allSessionTask] removeObject:task];
      
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
      if (failBlock) failBlock(error);
      [[self allSessionTask] removeObject:task];
  }];
    
    
    [sessionTask resume];
    
    !sessionTask ?: [[self allSessionTask] addObject:sessionTask];
    return sessionTask;
}

#pragma mark - 多文件上传
+ (NSArray *)uploadMultFileWithUrl:(NSString *)url
                         fileDatas:(NSArray *)datas
                              type:(NSString *)type
                              name:(NSString *)name
                          mimeType:(NSString *)mimeTypes
                     progressBlock:(XXUploadProgressBlock)progressBlock
                      successBlock:(XXMultUploadSuccessBlock)successBlock
                         failBlock:(XXMultUploadFailBlock)failBlock {
    
    __block NSMutableArray *sessions = [NSMutableArray array];
    __block NSMutableArray *responses = [NSMutableArray array];
    __block NSMutableArray *failResponse = [NSMutableArray array];
    
    dispatch_group_t uploadGroup = dispatch_group_create();
    
    NSInteger count = datas.count;
    for (int i = 0; i < count; i++) {
        __block XXURLSessionTask *session = nil;
        
        dispatch_group_enter(uploadGroup);
        
        session = [self uploadFileWithUrl:url
                                 fileData:datas[i]
                                     type:type name:name
                                 mimeType:mimeTypes
                            progressBlock:^(int64_t bytesWritten, int64_t totalBytes) {
                                if (progressBlock) progressBlock(bytesWritten,
                                                                 totalBytes);
                                
                            } successBlock:^(id response) {
                                [responses addObject:response];
                                
                                dispatch_group_leave(uploadGroup);
                                
                                [sessions removeObject:session];
                                
                            } failBlock:^(NSError *error) {
                                NSError *Error = [NSError errorWithDomain:url code:-999 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"第%d次上传失败",i]}];
                                
                                [failResponse addObject:Error];
                                
                                dispatch_group_leave(uploadGroup);
                                
                                [sessions removeObject:session];
                            }];
        
        [session resume];
        
        if (session) [sessions addObject:session];
    }
    
    [[self allSessionTask] addObjectsFromArray:sessions];
    
    dispatch_group_notify(uploadGroup, dispatch_get_main_queue(), ^{
        if (responses.count > 0) {
            if (successBlock) {
                successBlock([responses copy]);
                if (sessions.count > 0) {
                    [[self allSessionTask] removeObjectsInArray:sessions];
                }
            }
        }
        
        if (failResponse.count > 0) {
            if (failBlock) {
                failBlock([failResponse copy]);
                if (sessions.count > 0) {
                    [[self allSessionTask] removeObjectsInArray:sessions];
                }
            }
        }
        
    });
    
    return [sessions copy];
}

#pragma mark - 下载
+ (XXURLSessionTask *)downloadWithUrl:(NSString *)url
                        progressBlock:(XXDownloadProgress)progressBlock
                         successBlock:(XXDownloadSuccessBlock)successBlock
                            failBlock:(XXDownloadFailBlock)failBlock {
    NSString *type = nil;
    NSArray *subStringArr = nil;
    __block XXURLSessionTask *session = nil;
    
    NSURL *fileUrl = [[XXCacheManager shareManager] getDownloadDataFromCacheWithRequestUrl:url];
    
    if (fileUrl) {
        if (successBlock) successBlock(fileUrl);
        return nil;
    }
    
    if (url) {
        subStringArr = [url componentsSeparatedByString:@"."];
        if (subStringArr.count > 0) {
            type = subStringArr[subStringArr.count - 1];
        }
    }
    
    //响应内容序列化为二进制
    _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    session = [_sessionManager GET:url
                parameters:nil
                  progress:^(NSProgress * _Nonnull downloadProgress) {
                      if (progressBlock) progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
                      
                  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if (successBlock) {
                          //响应内容序列化为json
                          _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
                          NSData *dataObj = (NSData *)responseObject;
                          
                          [[XXCacheManager shareManager] storeDownloadData:dataObj requestUrl:url];
                          
                          NSURL *downFileUrl = [[XXCacheManager shareManager] getDownloadDataFromCacheWithRequestUrl:url];
                          
                          successBlock(downFileUrl);
                      }
                      
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      //响应内容序列化为json
                      _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
                      if (failBlock) {
                          failBlock (error);
                      }
                  }];
    
    [session resume];
    
    if (session) [[self allSessionTask] addObject:session];
    
    return session;
    
}

@end



@implementation XXNetworking (cache)
+ (NSUInteger)totalCacheSize {
    return [[XXCacheManager shareManager] totalCacheSize];
}

+ (NSUInteger)totalDownloadDataSize {
    return [[XXCacheManager shareManager] totalDownloadDataSize];
}

+ (void)clearDownloadData {
    [[XXCacheManager shareManager] clearDownloadData];
}

+ (NSString *)getDownDirectoryPath {
    return [[XXCacheManager shareManager] getDownDirectoryPath];
}

+ (NSString *)getCacheDiretoryPath {
    
    return [[XXCacheManager shareManager] getCacheDiretoryPath];
}

+ (void)clearTotalCache {
    [[XXCacheManager shareManager] clearTotalCache];
}

@end
