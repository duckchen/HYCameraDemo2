//
//  HYAlbum.h
//  HYCameraDemo2
//
//  Created by chy on 16/12/20.
//  Copyright © 2016年 Chy. All rights reserved.
//

#import "BaseEntity.h"

@interface HYAlbum : BaseEntity <NSCoding>

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * ID;


/**
 如果_ID存在，直接储存，否则创建新的相册，并赋值_ID(相册系统创建的ID)

 @param data <#data description#>
 */
-(void)saveImageToSystemAlbum:(NSData*)data;

@end
