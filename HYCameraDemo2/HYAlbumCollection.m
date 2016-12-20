//
//  HYAlbumCollection.m
//  HYCameraDemo2
//
//  Created by chy on 16/12/20.
//  Copyright © 2016年 Chy. All rights reserved.
//

#import "HYAlbumCollection.h"
#import "FCFileManager.h"
#import "HYAlbum.h"

static NSString * const HYAlbumListKey = @"albumList";

@interface HYAlbumCollection ()

@property (nonatomic, strong) NSMutableArray<HYAlbum *> * albumList;

@end

@implementation HYAlbumCollection

// MARK: - Getting methods
//--------------------------------------------------------------------

- (NSMutableArray *)albumList
{
    if (_albumList == nil) {
        _albumList = [NSMutableArray array];
    }
    
    return _albumList;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _albumList = [NSKeyedUnarchiver unarchiveObjectWithFile:self.filePath];
    }
    
    return self;
}

- (void)archive
{
    BOOL success = [NSKeyedArchiver archiveRootObject:self.albumList toFile:self.filePath];
    if (success) {
        NSLog(@"保存相册列表成功");
    }
}

- (NSString *)filePath
{
    NSString * document = NSSearchPathForDirectoriesInDomains(
                                                              NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [document
                          stringByAppendingPathComponent:@"/albumCollection"];
    if (![FCFileManager isDirectoryItemAtPath:filePath]) {
        [FCFileManager createDirectoriesForPath:filePath];
    }
    
    return filePath;
}

// MARK: - NSCoding delegate methods
//--------------------------------------------------------------------

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _albumList = [aDecoder decodeObjectForKey:HYAlbumListKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.albumList forKey:HYAlbumListKey];
}

// MARK: - Public methods
//--------------------------------------------------------------------

- (NSMutableArray *)albumListShallowCopy
{
    [self.lock lock];
    NSMutableArray * albumList = [NSMutableArray arrayWithArray:self.albumList];
    [self.lock unlock];
    
    return albumList;
}

- (void)addAlbum:(HYAlbum *)album
{
    [self.lock lock];
    [self.albumList addObject:album];
    [self.lock unlock];
}

@end
