//
//  HYZBaseRequest.h
//  HYZNetwork
//
//  Created by 黄亚州 on 2019/12/21.
//  Copyright © 2019 iOS开发者. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// http请求方式
typedef NS_ENUM(NSInteger, HYZRequestMethod) {
    /// http Get请求方式
    HYZRequestMethodGet = 1 << 0,
    /// http Post请求方式
    HYZRequestMethodPOST = 1 << 1,
    /// http Head请求方式
    HYZRequestMethodHEAD = 1 << 2,
    /// http Put请求方式
    HYZRequestMethodPUT = 1 << 3
};

/// http请求的编码格式
typedef NS_ENUM(NSInteger, HYZRequestSerializerType) {
    /// 普通的http的编码格式
    HYZRequestSerializerTypeHTTP = 1 << 0,
    /// json编码格式
    HYZRequestSerializerTypeJSON = 1 << 1
};

/// http请求返回结果的编码格式
typedef NS_ENUM(NSInteger, HYZResponseSerializerType) {
    /// 返回结果为普通的http的编码格式
    HYZResponseSerializerTypeHTTP = 1 << 0,
    /// 返回结果为json编码格式
    HYZResponseSerializerTypeJSON = 1 << 1,
    /// 返回结果为plist编码格式
    HYZResponseSerializerTypeXMLParser = 1 << 2
};

/// 请求scheme协议类型
typedef NS_ENUM(NSInteger, HYZSchemeProtocolType) {
    /// http请求协议类型
    HYZSchemeProtocolTypeHttp = 1 << 0,
    /// https请求协议类型
    HYZSchemeProtocolTypeHttps = 1 << 1
};

/// 请求优先级
typedef NS_ENUM(NSInteger, HYZRequestPriority) {
    /// 低级请求优先级
    HYZRequestPriorityLow = -1,
    /// 默认请求优先级
    HYZRequestPriorityDefault = 0,
    /// 高级请求优先级
    HYZRequestPriorityHigh = 1
};

@class HYZBaseRequest;
@protocol AFMultipartFormData;

/// 请求完成回调
/// @param request 请求对象
typedef void (^HYZRequestCompletionBlock) (__kindof HYZBaseRequest *request);

/// 多媒体上传构建回调，一般用于multipart/form-data
/// @param formData 多媒体资源
typedef void (^HYZConstructingBlock)(id <AFMultipartFormData> formData);

/// 请求结束后的代理，代理方法将在主线程中抛出
@protocol YZRequestDelegate <NSObject>

@optional
/// 请求结束时抛出的代理，无论成功或者失败使用的都是同一个
/// @param request 请求对象
- (void)didRequestFinished:(__kindof HYZBaseRequest *)request;

@end

/**
 * 网络请求对象，为网络请求做前期准备
 * 处理接口的相关
 */
@interface HYZBaseRequest : NSObject

/// 请求会话，只读
@property (nonatomic, strong, readonly) NSURLSessionTask *requestTask;
/// 请求优先级，支持iOS8以上系统，默认是YZRequestPriorityDefault
@property (nonatomic, assign, readonly) HYZRequestPriority requestPriority;
/// 请求过程中发生的错误，只读
@property (nonatomic, strong, readonly, nullable) NSError *error;
/// 请求返回对象，只读
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;
/// 请求返回的code值，只读
@property (nonatomic, readonly) NSInteger responseStatusCode;
/// 请求返回的原始数据，如果请求失败则为nil，只读
@property (nonatomic, strong, readonly, nullable) id responseObject;
/// 请求返回数据json字符串，如果请求失败则为nil，只读
@property (nonatomic, strong, readonly, nullable) NSString *responseString;
/// 请求完成的回调，包含了请求成功和失败，将在主线程中处理
@property (nonatomic, copy, nullable) HYZRequestCompletionBlock requestCompletionBlock;
/// 请求结束时的代理
@property (nonatomic, weak, nullable) id <YZRequestDelegate> delegate;

#pragma mark - 请求配置，可根据自己的使用场景重写以下方法

/// 请求超时时间
/// @return 超时时间
- (NSTimeInterval)requestTimeoutInterval;

/// 请求时是否允许使用蜂窝网络
/// @return 是否允许使用蜂窝网络
- (BOOL)allowsCellularAccess;

/// HTTP 请求方式
/// @return 请求方式
- (HYZRequestMethod)requestMethod;

/// http请求的编码格式
/// @return 编码格式
- (HYZRequestSerializerType)requestSerializerType;

/// http请求返回结果的编码格式
/// @return 编码格式
- (HYZResponseSerializerType)responseSerializerType;

/// http请求头所携带的app用户账号和密码数据
/// 数组包含了2个元素，第一个元素是账号，最后一个元素是密码
/// @return 用户账号和密码组成的数组
- (NSArray <NSString *> *)requestAuthorizationHeaderFieldArray;

/// http请求头中包含的请求参数数据
/// 格式为Key-Value方式
/// @return http请求头中的参数
- (NSDictionary <NSString *, NSString *> *)requestHeaderFieldValueDictionary;

/// 请求scheme协议类型
/// @return scheme协议类型
- (HYZSchemeProtocolType)requestSchemeProtocolType;

/// 请求域名（example.com）
/// @return 请求域名
- (NSString *)requestRealmNameString;

/// 请求接口地址路径（/api/v1/login）
/// @return 请求地址
- (NSString *)requestInterfaceURLString;

/// 请求完整URL地址
/// @return 请求完整地址
- (NSString *)requestFullURLString;

/// 请求参数
/// @return 请求参数
- (id)requestParam;

/// 多媒体上传，文件构建回调
/// @return 多媒体上传回调
- (HYZConstructingBlock)constructingBodyBlock;

/// 检查responseStatusCode是否有效
/// @return responseStatusCode是否有效
- (BOOL)statusCodeValidator;

/// 设定请求完成的回调
/// @param block 请求完成回调
- (void)setCompletionBlock:(HYZRequestCompletionBlock)block;

/// 清理完成回调
- (void)clearCompletionBlock;

/// 网络不给力校验器
/// @return 网络是否不给力
- (BOOL)networkBadValidator;

#pragma mark - 请求操作

/// 开启请求
- (void)startRequest;

/// 停止请求
- (void)stopRequest;

/// 开启请求，并设定请求完成回调
/// @param block 请求完成回调
- (void)startRequestWithCompletionBlock:(HYZRequestCompletionBlock)block;

@end

NS_ASSUME_NONNULL_END
