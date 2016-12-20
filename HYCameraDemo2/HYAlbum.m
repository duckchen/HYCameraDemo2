//
//  HYAlbum.m
//  HYCameraDemo2
//
//  Created by chy on 16/12/20.
//  Copyright © 2016年 Chy. All rights reserved.
//

#import "HYAlbum.h"

@implementation HYAlbum

- (instancetype)init
{
    self = [super init];
    if (self) {
        _ID = [NSUUID UUID];
    }
    
    return self;
}

@end
