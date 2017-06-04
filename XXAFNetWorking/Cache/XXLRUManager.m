//
//  XXLRUManager.m
//  XXAFNetWorking
//
//  Created by Beelin on 2017/6/3.
//  Copyright © 2017年 Beelin. All rights reserved.
//

#import "XXLRUManager.h"

static NSMutableArray *operationQueue = nil;
static NSString *const kLRUManagerName = @"XXLRUManagerName";

@implementation XXLRUManager
+ (XXLRUManager *)shareManager {
    static XXLRUManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[XXLRUManager alloc] init];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kLRUManagerName]) {
            operationQueue = [NSMutableArray arrayWithArray:(NSArray *)[[NSUserDefaults standardUserDefaults] objectForKey:kLRUManagerName]];
        }else {
            operationQueue = [NSMutableArray array];
        }
    });
    return manager;
}

- (void)addFileNode:(NSString *)filename {
    NSArray *array = [operationQueue copy];
    //优化遍历
    NSArray *reverseArray = [[array reverseObjectEnumerator] allObjects];
    [reverseArray enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"fileName"] isEqualToString:filename]) {
            [operationQueue removeObjectAtIndex:idx];
            *stop = YES;
        }
    }];
    
    NSDate *date = [NSDate date];
    NSDictionary *newDic = @{@"fileName":filename,@"date":date};
    
    [operationQueue addObject:newDic];
    
    [[NSUserDefaults standardUserDefaults] setObject:[operationQueue copy] forKey:kLRUManagerName];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)refreshIndexOfFileNode:(NSString *)filename {
    [self addFileNode:filename];
}

- (NSArray *)removeLRUFileNodeWithCacheTime:(NSTimeInterval)time {
    NSMutableArray *result = [NSMutableArray array];
    
    if (operationQueue.count > 0) {
        NSArray *tmpArray = [operationQueue copy];
        [tmpArray enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDate *date = obj[@"date"];
            NSDate *newDate = [date dateByAddingTimeInterval:time];
            if ([[NSDate date] compare:newDate] == NSOrderedDescending) {
                [result addObject:obj[@"fileName"]];
                [operationQueue removeObjectAtIndex:idx];
            }
        }];
        
        if (result.count == 0) {
            NSString *removeFileName = [operationQueue firstObject][@"fileName"];
            [result addObject:removeFileName];
            [operationQueue removeObjectAtIndex:0];
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:[operationQueue copy] forKey:kLRUManagerName];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return [result copy];
}

- (NSArray *)currentQueue {
    return [operationQueue copy];
}

@end
