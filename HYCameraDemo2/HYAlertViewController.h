//
//  HYAlertViewController.h
//  HYCameraDemo2
//
//  Created by chy on 16/12/20.
//  Copyright © 2016年 Chy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HYAlertViewController : UIAlertController

+ (HYAlertViewController *)alertWithTitle:(NSString *)title handler:(void (^ __nullable)(UITextField *textField))configurationHandler;

@end
