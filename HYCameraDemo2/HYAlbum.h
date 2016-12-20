//
//  HYAlbum.h
//  HYCameraDemo2
//
//  Created by chy on 16/12/20.
//  Copyright © 2016年 Chy. All rights reserved.
//

#import "BaseEntity.h"

@interface HYAlbum : BaseEntity

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSUUID   * ID;
@property (nonatomic, assign) BOOL      isDocCreated;

@end
