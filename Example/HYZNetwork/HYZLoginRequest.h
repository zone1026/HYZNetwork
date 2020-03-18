//
//  HYZLoginRequest.h
//  HYZNetwork_Example
//
//  Created by 黄亚州 on 2020/3/18.
//  Copyright © 2020 zone1026. All rights reserved.
//

#import "HYZExampleRequest.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 具体某个请求对象，比如登录
 */
@interface HYZLoginRequest : HYZExampleRequest

/// 初始化登陆接口对象
/// @param userName 账户名
/// @param password 账户密码
- (instancetype)initUserName:(nonnull NSString *)userName withPassword:(nonnull NSString *)password NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
