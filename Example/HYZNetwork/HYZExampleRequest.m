//
//  HYZExampleRequest.m
//  HYZNetwork_Example
//
//  Created by 黄亚州 on 2020/3/18.
//  Copyright © 2020 zone1026. All rights reserved.
//

#import "HYZExampleRequest.h"

@interface HYZExampleRequest ()
/// 请求返回数据回调
@property (nonatomic, copy) HYZExampleResponseBlock responseBlock;

@end

@implementation HYZExampleRequest

#pragma mark - Public

- (void)startExampleRequestWithCompletionBlock:(HYZExampleResponseBlock)block {
    self.responseBlock = block;
    
    __weak typeof(self) weakSelf = self;
    [self startRequestWithCompletionBlock:^(__kindof HYZBaseRequest * _Nonnull request) {
        [weakSelf handleRequestCompletion:request];
    }];
}

#pragma mark - Private

/// 请求完成后的处理
/// @param request 请求对象
- (void)handleRequestCompletion:(HYZBaseRequest *)request {
    HYZExampleResponseModel *model = [[HYZExampleResponseModel alloc] init];
    model.code = request.responseStatusCode;
    if (request.error != nil) {
        model.msg = request.error.localizedDescription;
    }
    
    if (request.responseObject != nil &&
        [request.responseObject isKindOfClass:[NSDictionary class]]) {
        model.code = [[request.responseObject objectForKey:@"msg"] integerValue];
        model.msg = [request.responseObject objectForKey:@"msg"];
        model.responseData = [request.responseObject objectForKey:@"data"];
    }
    
    if (self.responseBlock != nil) {
        self.responseBlock(model);
    }
}

#pragma mark - HYZNetwork 配置

/// 请求超时时间
/// @return 超时时间
- (NSTimeInterval)requestTimeoutInterval {
    return 30.0f;
}

/// 请求时是否允许使用蜂窝网络
/// @return 是否允许使用蜂窝网络
- (BOOL)allowsCellularAccess {
    return YES;
}

/// 请求域名（example.com）
/// @return 请求域名
- (NSString *)requestRealmNameString {
    return @"xxx.example.com";
}

/// http请求的编码格式
/// @return 编码格式
- (HYZRequestSerializerType)requestSerializerType {
    return HYZRequestSerializerTypeJSON;
}

/// http请求返回结果的编码格式
/// @return 编码格式
- (HYZResponseSerializerType)responseSerializerType {
    return HYZResponseSerializerTypeJSON;
}

/// http请求头所携带的app用户账号和密码数据
/// 数组包含了2个元素，第一个元素是账号，最后一个元素是密码
/// @return 用户账号和密码组成的数组
- (NSArray <NSString *> *)requestAuthorizationHeaderFieldArray {
    return nil;
}

/// http请求头中包含的请求参数数据
/// 格式为Key-Value方式
/// @return http请求头中的参数
- (NSDictionary <NSString *, NSString *> *)requestHeaderFieldValueDictionary {
    return @{@"Content-Type":@"application/json; charset=utf-8",@"token":@"xxxxxx",@"dateTime":[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]]};
}

/// 多媒体上传，文件构建回调
/// @return 多媒体上传回调
- (HYZConstructingBlock)constructingBodyBlock {
    return nil;
}

/// 检查responseStatusCode是否有效
/// @return responseStatusCode是否有效
- (BOOL)statusCodeValidator {
    return [super statusCodeValidator];
}

@end

@implementation HYZExampleResponseModel

@end
