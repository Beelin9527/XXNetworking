//
//  XXLRUManager.h
//  XXAFNetWorking
//
//  Created by Beelin on 2017/6/3.
//  Copyright © 2017年 Beelin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XXLRUManager : NSObject
/**
 *  当前队列的情况
 */
@property (nonatomic, copy, readonly)NSArray *currentQueue;

+ (XXLRUManager *)shareManager;

/**
 *  添加新的结点
 *
 *  @param filename 文件名字
 */
- (void)addFileNode:(NSString *)filename;

/**
 *  调整结点位置，一般用于命中缓存时
 *
 *  @param filename 文件名字
 */
- (void)refreshIndexOfFileNode:(NSString *)filename;

/**
 *  删除最近最久未使用的缓存
 *
 *  @param time 缓存时间
 *
 *  @return 删除结点的文件名列表
 */
- (NSArray *)removeLRUFileNodeWithCacheTime:(NSTimeInterval) time;
@end
