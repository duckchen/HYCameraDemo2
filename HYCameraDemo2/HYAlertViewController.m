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

+ (HYAlertViewController *)alertWithTitle:(NSString *)title handler:(void (^ __nullable)(UITextField *textField))configurationHandler
{
    HYAlertViewController * ctr = [[self alloc] init];
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:nil];
    [ctr addAction:alertAction];
    [ctr addTextFieldWithConfigurationHandler:configurationHandler];
    
    
}

@end
