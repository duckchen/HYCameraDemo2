//
//  HYAlertViewController.m
//  HYCameraDemo2
//
//  Created by chy on 16/12/20.
//  Copyright © 2016年 Chy. All rights reserved.
//

#import "HYAlertViewController.h"

@interface HYAlertViewController ()

@end

@implementation HYAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message
{
    HYAlertViewController * ctr = [super alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:nil];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleCancel handler:nil];
    [ctr addAction:okAction];
    [ctr addAction:cancelAction];
    [ctr addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"相册名";
    }];
    
    return ctr;
}

@end
