//
//  HYZNetworkPrivate.h
//  HYZNetwork
//
//  Created by 黄亚州 on 2020/2/25.
//  Copyright © 2020 iOS开发者. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYZBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface HYZNetworkPrivate : NSObject

@end

@interface HYZBaseRequest (Setter)
/// 请求会话，开放读写权限
@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
/// 请求返回数据，如果请求失败则为nil，开放读写权限
@property (nonatomic, strong, readwrite, nullable) id responseObject;
/// 请求返回数据json字符串，如果请求失败则为nil，开放读写权限
@property (nonatomic, strong, readwrite, nullable) NSString *responseString;
/// 请求过程中发生的错误，开放读写权限
@property (nonatomic, strong, readwrite, nullable) NSError *error;

@end

NS_ASSUME_NONNULL_END
