//
//  XXNetworking.h
//  XXAFNetWorking
//
//  Created by Beelin on 2017/6/4.
//  Copyright © 2017年 Beelin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, XXNetworkStatusType) {
    /** 未知网络*/
    XXNetworkStatusUnknown,
    /** 无网络*/
    XXNetworkStatusNotReachable,
    /** 手机网络*/
    XXNetworkStatusReachableViaWWAN,
    /** WIFI网络*/
    XXNetworkStatusReachableViaWiFi
};

/**
 *  请求任务
 */
typedef NSURLSessionTask XXURLSessionTask;

/**
 *  成功回调
 *
 *  @param response 成功后返回的数据
 */
typedef void(^XXResponseSuccessBlock)(id response);

/**
 *  失败回调
 *
 *  @param error 失败后返回的错误信息
 */
typedef void(^XXResponseFailBlock)(NSError *error);

/**
 *  下载进度
 *
 *  @param bytesRead              已下载的大小
 *  @param totalBytes                总下载大小
 */
typedef void (^XXDownloadProgress)(int64_t bytesRead,
int64_t totalBytes);

/**
 *  下载成功回调
 *
 *  @param url                       下载存放的路径
 */
typedef void(^XXDownloadSuccessBlock)(NSURL *url);


/**
 *  上传进度
 *
 *  @param bytesWritten              已上传的大小
 *  @param totalBytes                总上传大小
 */
typedef void(^XXUploadProgressBlock)(int64_t bytesWritten,
int64_t totalBytes);
/**
 *  多文件上传成功回调
 *
 *  @param responses 成功后返回的数据
 */
typedef void(^XXMultUploadSuccessBlock)(NSArray *responses);

/**
 *  多文件上传失败回调
 *
 *  @param errors 失败后返回的错误信息
 */
typedef void(^XXMultUploadFailBlock)(NSArray *errors);

typedef XXDownloadProgress XXGetProgress;

typedef XXDownloadProgress XXPostProgress;

typedef XXResponseFailBlock XXDownloadFailBlock;


/** 网络状态的Block*/
typedef void(^XXNetworkStatus)(XXNetworkStatusType status);


@interface XXNetworking : NSObject
/**
 有网YES, 无网:NO
 */
+ (BOOL)isNetwork;

/**
 手机网络:YES, 反之:NO
 */
+ (BOOL)isWWANNetwork;

/**
 WiFi网络:YES, 反之:NO
 */
+ (BOOL)isWiFiNetwork;

/**
 取消所有HTTP请求
 */
+ (void)cancelAllRequest;

/**
 实时获取网络状态,通过Block回调实时获取(此方法可多次调用)
 */
+ (void)networkStatusWithBlock:(XXNetworkStatus)networkStatus;

/**
 取消指定URL的HTTP请求
 */
+ (void)cancelRequestWithURL:(NSString *)URL;

/**
 *  GET请求
 *
 *  @param url              请求路径
 *  @param cache            是否缓存
 *  @param refresh          是否刷新请求(遇到重复请求，若为YES，则会取消旧的请求，用新的请求，若为NO，则忽略新请求，用旧请求)
 *  @param params           拼接参数
 *  @param progressBlock    进度回调
 *  @param successBlock     成功回调
 *  @param failBlock        失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (XXURLSessionTask *)getWithUrl:(NSString *)url
                  refreshRequest:(BOOL)refresh
                           cache:(BOOL)cache
                          params:(NSDictionary *)params
                   progressBlock:(XXGetProgress)progressBlock
                    successBlock:(XXResponseSuccessBlock)successBlock
                       failBlock:(XXResponseFailBlock)failBlock;




/**
 *  POST请求
 *
 *  @param url              请求路径
 *  @param cache            是否缓存
 *  @param refresh          解释同上
 *  @param params           拼接参数
 *  @param progressBlock    进度回调
 *  @param successBlock     成功回调
 *  @param failBlock        失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (XXURLSessionTask *)postWithUrl:(NSString *)url
                   refreshRequest:(BOOL)refresh
                            cache:(BOOL)cache
                           params:(NSDictionary *)params
                    progressBlock:(XXPostProgress)progressBlock
                     successBlock:(XXResponseSuccessBlock)successBlock
                        failBlock:(XXResponseFailBlock)failBlock;



/**
 *  上传单/多张图片
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param name       图片对应服务器上的字段
 *  @param images     图片数组
 *  @param fileNames  图片文件名数组, 可以为nil, 数组内的文件名默认为当前日期时间"yyyyMMddHHmmss"
 *  @param imageScale 图片文件压缩比 范围 (0.f ~ 1.f)
 *  @param imageType  图片文件的类型,例:png、jpg(默认类型)....
 *  @param progressBlock   上传进度信息
 *  @param successBlock    请求成功的回调
 *  @param failBlock    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (XXURLSessionTask *)uploadImagesWithURL:(NSString *)URL
                                        parameters:(id)parameters
                                              name:(NSString *)name
                                            images:(NSArray<UIImage *> *)images
                                         fileNames:(NSArray<NSString *> *)fileNames
                                        imageScale:(CGFloat)imageScale
                                         imageType:(NSString *)imageType
                                          progress:(XXUploadProgressBlock)progressBlock
                                           success:(XXResponseSuccessBlock)successBlock
                                           failure:(XXResponseFailBlock)failBlock;

/**
 *  文件上传
 *
 *  @param url              上传文件接口地址
 *  @param data             上传文件数据
 *  @param type             上传文件类型
 *  @param name             上传文件服务器文件夹名
 *  @param mimeType         mimeType
 *  @param progressBlock    上传文件路径
 *	@param successBlock     成功回调
 *	@param failBlock		失败回调
 *
 *  @return 返回的对象中可取消请求
 */
+ (XXURLSessionTask *)uploadFileWithUrl:(NSString *)url
                               fileData:(NSData *)data
                                   type:(NSString *)type
                                   name:(NSString *)name
                               mimeType:(NSString *)mimeType
                          progressBlock:(XXUploadProgressBlock)progressBlock
                           successBlock:(XXResponseSuccessBlock)successBlock
                              failBlock:(XXResponseFailBlock)failBlock;


/**
 *  多文件上传
 *
 *  @param url           上传文件地址
 *  @param datas         数据集合
 *  @param type          类型
 *  @param name          服务器文件夹名
 *  @param mimeTypes      mimeTypes
 *  @param progressBlock 上传进度
 *  @param successBlock  成功回调
 *  @param failBlock     失败回调
 *
 *  @return 任务集合
 */
+ (NSArray *)uploadMultFileWithUrl:(NSString *)url
                         fileDatas:(NSArray *)datas
                              type:(NSString *)type
                              name:(NSString *)name
                          mimeType:(NSString *)mimeTypes
                     progressBlock:(XXUploadProgressBlock)progressBlock
                      successBlock:(XXMultUploadSuccessBlock)successBlock
                         failBlock:(XXMultUploadFailBlock)failBlock;

/**
 *  文件下载
 *
 *  @param url           下载文件接口地址
 *  @param progressBlock 下载进度
 *  @param successBlock  成功回调
 *  @param failBlock     下载回调
 *
 *  @return 返回的对象可取消请求
 */
+ (XXURLSessionTask *)downloadWithUrl:(NSString *)url
                        progressBlock:(XXDownloadProgress)progressBlock
                         successBlock:(XXDownloadSuccessBlock)successBlock
                            failBlock:(XXDownloadFailBlock)failBlock;


@end

@interface XXNetworking (cache)

/**
 *  获取缓存目录路径
 *
 *  @return 缓存目录路径
 */
+ (NSString *)getCacheDiretoryPath;

/**
 *  获取下载目录路径
 *
 *  @return 下载目录路径
 */
+ (NSString *)getDownDirectoryPath;

/**
 *  获取缓存大小
 *
 *  @return 缓存大小
 */
+ (NSUInteger)totalCacheSize;

/**
 *  清除所有缓存
 */
+ (void)clearTotalCache;

/**
 *  获取所有下载数据大小
 *
 *  @return 下载数据大小
 */
+ (NSUInteger)totalDownloadDataSize;

/**
 *  清除下载数据
 */
+ (void)clearDownloadData;

@end

