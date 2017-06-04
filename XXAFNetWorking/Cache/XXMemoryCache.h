//
//  XXMemoryCache.h
//  XXAFNetWorking
//
//  Created by Beelin on 2017/6/3.
//  Copyright © 2017年 Beelin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXMemoryCache : NSObject
/**
 *  将数据写入内存
 *
 *  @param data 数据
 *  @param key  键值
 */
+ (void)writeData:(id) data forKey:(NSString *)key;

/**
 *  从内存中读取数据
 *
 *  @param key 键值
 *
 *  @return 数据
 */
+ (id)readDataWithKey:(NSString *)key;
@end
