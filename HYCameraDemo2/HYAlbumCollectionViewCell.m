//
//  HYAlbumCollectionViewCell.m
//  HYCameraDemo2
//
//  Created by chy on 16/12/20.
//  Copyright © 2016年 Chy. All rights reserved.
//

#import "HYAlbumCollectionViewCell.h"

@interface HYAlbumCollectionViewCell ()

@property (nonatomic, strong) UILabel * titleLabel;

@end

@implementation HYAlbumCollectionViewCell

// MARK: - Getting methods
//--------------------------------------------------------------------
- (UILabel *)titleLabel
{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 3, self.contentView.bounds.size.width, 30)];
        _titleLabel.textColor = [UIColor blueColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:12];
        [self.contentView addSubview:_titleLabel];
    }
    
    return _titleLabel;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

- (void)configCellWithTitle:(NSString *)title selected:(BOOL)selected
{
    self.titleLabel.text = title;
    if (selected) {
        self.titleLabel.font = [UIFont systemFontOfSize:15];
    } else {
        self.titleLabel.font = [UIFont systemFontOfSize:12];
    }
}

@end
