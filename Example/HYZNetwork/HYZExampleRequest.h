//
//  HYZExampleRequest.h
//  HYZNetwork_Example
//
//  Created by 黄亚州 on 2020/3/18.
//  Copyright © 2020 zone1026. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HYZNetwork/HYZNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@class HYZExampleResponseModel;

/// 请求结果回调
/// @param responseModel 请求返回数据模型
typedef void (^HYZExampleResponseBlock)(__kindof HYZExampleResponseModel *responseModel);

/**
 * 根据自己的项目重构请求对象
 *
 * 配置请求超时时间、请求方式、请求域名等等
 */
@interface HYZExampleRequest : HYZBaseRequest
 
/// 开始请求接口
/// @param block 请求完成后的回调
- (void)startExampleRequestWithCompletionBlock:(HYZExampleResponseBlock)block;

@end

@interface HYZExampleResponseModel : NSObject
/// 请求code码，后台返回的
@property (nonatomic, assign) NSInteger code;
/// 请求成功或者失败的描述信息，后台返回的
@property (nonatomic, strong) NSString *msg;
/// 请求拿到的数据
@property (nonatomic, strong) id responseData;

@end

NS_ASSUME_NONNULL_END
