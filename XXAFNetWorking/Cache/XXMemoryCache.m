//
//  XXMemoryCache.m
//  XXAFNetWorking
//
//  Created by Beelin on 2017/6/3.
//  Copyright © 2017年 Beelin. All rights reserved.
//

#import "XXMemoryCache.h"
#import <UIKit/UIKit.h>

@implementation XXMemoryCache
+ (NSCache *)shareCache {
    static NSCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
    });
    //当收到内存警报时，清空内存缓存
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [cache removeAllObjects];
    }];
    return cache;
}

+ (void)writeData:(id)data forKey:(NSString *)key {
    assert(data);
    assert(key);
    
    NSCache *cache = [XXMemoryCache shareCache];
    [cache setObject:data forKey:key];
}

+ (id)readDataWithKey:(NSString *)key {
    assert(key);
    id data = nil;
    
    NSCache *cache = [XXMemoryCache shareCache];
    data = [cache objectForKey:key];
    
    return data;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}
@end
