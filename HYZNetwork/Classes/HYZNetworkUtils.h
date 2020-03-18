//
//  HYZNetworkUtils.h
//  HYZNetwork
//
//  Created by 黄亚州 on 2020/3/10.
//  Copyright © 2020 iOS开发者. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HYZBaseRequest;

@interface HYZNetworkUtils : NSObject

/// 请求对象对应的字符编码
/// @param request 请求对象
+ (NSStringEncoding)stringEncodingWithRequest:(HYZBaseRequest *)request;

@end

NS_ASSUME_NONNULL_END
