//
//  HYZViewController.m
//  HYZNetwork
//
//  Created by zone1026 on 03/18/2020.
//  Copyright (c) 2020 zone1026. All rights reserved.
//

#import "HYZViewController.h"
#import "HYZLoginRequest.h"

@interface HYZViewController ()

@end

@implementation HYZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnLoginClick:(UIButton *)sender {
    HYZLoginRequest *request = [[HYZLoginRequest alloc] initUserName:@"131xxxx1234" withPassword:@"123"];
    [request startExampleRequestWithCompletionBlock:^(__kindof HYZExampleResponseModel * _Nonnull responseModel) {
        
    }];
}

@end
