# HYZNetwork

[![CI Status](https://img.shields.io/travis/zone1026/HYZNetwork.svg?style=flat)](https://travis-ci.org/zone1026/HYZNetwork)
[![Version](https://img.shields.io/cocoapods/v/HYZNetwork.svg?style=flat)](https://cocoapods.org/pods/HYZNetwork)
[![License](https://img.shields.io/cocoapods/l/HYZNetwork.svg?style=flat)](https://cocoapods.org/pods/HYZNetwork)
[![Platform](https://img.shields.io/cocoapods/p/HYZNetwork.svg?style=flat)](https://cocoapods.org/pods/HYZNetwork)

## HYZNetwork 是什么

HYZNetwork 是基于 [AFNetworking][AFNetworking] 封装的iOS端简易网络库，通过创建请求对象的方式处理网络接口

## HYZNetwork 的基本思路

HYZNetwork的基本思想是参考[YTKNetwork](https://github.com/yuantiku/YTKNetwork.git)的思路，把每一个网络请求封装成对象，与第三方网络库剥离，使第三方库类文件不必散落在各个业务模块中。

目前HYZNetwork的功能相对比较单一，比如接口数据存储功能还没实现，在后期迭代中会开发。

## 安装

你可以在 Podfile 中加入下面一行代码来使用 HYZNetwork

```ruby
pod 'HYZNetwork'
```

## 安装要求

HYZNetwork 依赖于 AFNetworking 3.2.1版本进行的封装，可以在 [AFNetworking README](https://github.com/AFNetworking/AFNetworking) 中找到更多关于依赖版本有关的信息。

## 相关的使用说明

HYZNetwork 的思路是把每一个网络请求封装成对象。目前只开放了HYZBaseRequest，建议根据自己的项目需求再次封装HYZBaseRequest。

### HYZBaseRequest 类

 HYZBaseRequest是请求对象基类，通过对父类的封装重写以适应自己的项目。比如Example项目中的HYZExampleRequest，统一配置有关网络请求的参数，请求超时时间、请求方式、请求域名等等。

 ```
 // HYZExampleRequest.h
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

// HYZExampleRequest.m

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

```

每个网络请求继承 HYZExampleRequest 类后，需要用方法重写的方式，来指定网络请求的具体信息，比如我们要做一个登录接口。那么应该这么写，如下所示：

```objectivec
// HYZLoginRequest.h

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


// HYZLoginRequest.m

#import "HYZLoginRequest.h"

@interface HYZLoginRequest ()
/// 账户名
@property (nonatomic, strong) NSString *userName;
/// 账户密码
@property (nonatomic, strong) NSString *password;

@end

@implementation HYZLoginRequest

#pragma mark - init

- (instancetype)init {
    return [self initUserName:@"xxx" withPassword:@"xxx"];
}

- (instancetype)initUserName:(NSString *)userName withPassword:(NSString *)password {
    if (self = [super init]) {
        self.userName = userName;
        self.password = password;
    }
    
    return self;
}

#pragma mark - 请求配置

/// 登录接口 HTTP 请求方式
/// @return 请求方式
- (HYZRequestMethod)requestMethod {
    return HYZRequestMethodPOST;
}

/// 登录接口请求scheme协议类型
/// @return scheme协议类型
- (HYZSchemeProtocolType)requestSchemeProtocolType {
    return HYZSchemeProtocolTypeHttp;
}

/// 登录接口地址路径（/api/v1/login）
/// @return 请求地址
- (NSString *)requestInterfaceURLString {
    return @"/api/v1/login";
}

/// 登录接口请求参数
/// @return 请求参数
- (id)requestParam {
    return @{
        @"user_name":self.userName,
        @"password":self.password,
        @"device_id":@"f9a9b953527df49e",
        @"offcn-dateTime":@"2020-03-18 19:11:21",
        @"appsystem":@"iOS",
        @"device_type":@"iphone 6s",
        @"appversion":@"1.0.0"
    };
}

```

通过这个示例中，我们可以看到：

 * 通过重写requestTimeoutInterval、requestRealmNameString、requestSerializerType、responseSerializerType、requestHeaderFieldValueDictionary等方法HYZExampleRequest类完善了网络接口的超时时间、接口域名、请求头等数据。
 * HYZExampleRequest也重写了自己项目所需的开始请求方法、请求返回block等方法
 * 通过重写requestMethod、requestSchemeProtocolType、requestInterfaceURLString、requestParam方法HYZLoginRequest类完善了登录接口所需参数。
 
## HYZLoginRequest 使用

在构造完成 HYZLoginRequest 之后，在项目中如何使用呢？我们在HYZViewController页面中调用 HYZLoginRequest，并使用block 的方式来取得网络请求结果：

```objectivec
- (IBAction)btnLoginClick:(UIButton *)sender {
    HYZLoginRequest *request = [[HYZLoginRequest alloc] initUserName:@"131xxxx1234" withPassword:@"123"];
    [request startExampleRequestWithCompletionBlock:^(__kindof HYZExampleResponseModel * _Nonnull responseModel) {
        
    }];
}

```

## 感谢

HYZNetwork 基于 [YTKNetwork][YTKNetwork] 和 [AFNetworking][AFNetworking]进行开发，感谢他们对开源社区做出的贡献。

## 联系方式

zone1026, 1024105345@offcn.com

## 协议

HYZNetwork 被许可在 MIT 协议下使用。查阅 LICENSE 文件来获得更多信息。

<!-- external links -->
[AFNetworking]:https://github.com/AFNetworking/AFNetworking
[YTKNetwork]:https://github.com/yuantiku/YTKNetwork.git
