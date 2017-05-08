//
//  debugViewController.m
//  FNDebugManagerPod
//
//  Created by JR on 08/16/2016.
//  Copyright (c) 2016 JR. All rights reserved.
//

#import "debugViewController.h"
#import "FNDebugManager.h"
#import "FNDebugSettingViewController.h"


static NSString *kMerchantDomainDev = @"http://mall-mobile-api.dev1.fn:8080";
static NSString *kMerchantDomainBeta = @"https://mall-mobile-api.beta1.fn";
static NSString *kMerchantDomainPreview = @"https://preview-interface-merchant.feiniu.com";
static NSString *kMerchantDomainOnline = @"https://interface-merchant.feiniu.com";
static NSString *kApiVersion = @"i100";

@interface debugViewController ()

@end

@implementation debugViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[FNDebugManager shareManager] addTrustedCertificates:nil];
    [[FNDebugManager shareManager] configDomainType];
    [[FNDebugManager shareManager] saveEviromentChnageSuccess:^{
        NSLog(@"changeOk");
    } failure:^{
        NSLog(@"changeNotOk");
    }];
    [[FNDebugManager shareManager] configCid:@"1234" deviceToken:@"123456789012345678901234567890123456789012345678901234567890"];
    
    WS(weakSelf)
    [[FNDebugManager shareManager] changeEviroment:^(FNDomainType domainType) {
        return  [weakSelf urlForEnviroment:domainType];
    }];
}

- (NSString *)urlForEnviroment:(FNDomainType)domainType
{
    NSString *domainUrlString;
    switch (domainType) {
        case FNDomainTypeDev:
            domainUrlString = kMerchantDomainDev;
            break;
        case FNDomainTypeBeta:
            domainUrlString = kMerchantDomainDev;
            break;
        case FNDomainTypePreview:
            domainUrlString = kMerchantDomainPreview;
            break;
        case FNDomainTypeOnline:
            domainUrlString = kMerchantDomainOnline;
            break;
            
        default:
            break;
    }
    return [self joinUrl:domainUrlString];
}

- (NSString *)joinUrl:(NSString *)domainUrlString
{
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/getConfig/%@",domainUrlString,@"info",@"i100"];
    return urlString;
}

- (IBAction)changeEviroment:(id)sender {
    FNDebugSettingViewController *debugVc = [[FNDebugSettingViewController alloc] init];
    [self.navigationController pushViewController:debugVc animated:YES];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
