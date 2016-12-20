//
//  HYAlbumCollection.h
//  HYCameraDemo2
//
//  Created by chy on 16/12/20.
//  Copyright © 2016年 Chy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseEntity.h"

@class HYAlbum;

@interface HYAlbumCollection : BaseEntity <NSCoding>

- (void)archive;

- (NSMutableArray *)albumListShallowCopy;

- (void)addAlbum:(HYAlbum *)album;

@end
