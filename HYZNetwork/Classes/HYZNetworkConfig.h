//
//  HYZNetworkConfig.h
//  HYZNetwork
//
//  Created by 黄亚州 on 2019/12/21.
//  Copyright © 2019 iOS开发者. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AFSecurityPolicy;

/**
 处理http请求相关网络配置信息
 */
@interface HYZNetworkConfig : NSObject
/// 请求回话配置
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
/// 安全性策略
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

/// 网络请求配置单例对象
/// @return 单例对象
+ (HYZNetworkConfig *)sharedConfig;

@end

NS_ASSUME_NONNULL_END
