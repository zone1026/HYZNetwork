//
//  HYZNetworkManager.m
//  HYZNetwork
//
//  Created by 黄亚州 on 2019/12/21.
//  Copyright © 2019 iOS开发者. All rights reserved.
//

#import "HYZNetworkManager.h"
#import "HYZNetworkConfig.h"
#import "HYZNetworkPrivate.h"
#import "HYZNetworkUtils.h"

#import <pthread/pthread.h>

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@interface HYZNetworkManager ()
/// http请求响应着
@property (nonatomic, strong) AFHTTPSessionManager *manager;
/// 网络请求相关配置
@property (nonatomic, strong) HYZNetworkConfig *config;
/// (普通的http的编码格式，二进制) 数据解析器
@property (nonatomic, strong) AFHTTPResponseSerializer *httpResponseSerializer;
/// json码格式 数据解析器
@property (nonatomic, strong) AFJSONResponseSerializer *jsonResponseSerializer;
/// plist编码格式 数据解析器
@property (nonatomic, strong) AFXMLParserResponseSerializer *xmlParserResponseSerialzier;
/// 请求池缓存字典。key是任务标识（taskIdentifier），value是请求对象（YZBaseRequest）
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, HYZBaseRequest *> *requestsRecordDictM;
@end

@implementation HYZNetworkManager {
    /// 互斥锁
    pthread_mutex_t _lock;
    /// 设置状态码,只有这些状态码表示获得了有效的响应。
    NSIndexSet *_allStatusCodes;
}

+ (HYZNetworkManager *)sharedManager {
    static HYZNetworkManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

#pragma mark - Init

- (instancetype)init {
    if (self = [super init]) {
        /// 请求时的回调线程，如果为nil则在main queue中进行
        self.manager.completionQueue = dispatch_queue_create("com.hyz.YZNetwork.block", DISPATCH_QUEUE_CONCURRENT);
        // 以动态方式创建互斥锁
        pthread_mutex_init(&_lock, NULL);
    }
    
    return self;
}

#pragma mark - Public Methods

#pragma mark - Private Methods

/// 处理数据解析器的配置属性
/// @param responseSerializer 数据解析器
- (void)handleResponseSerializerProperty:(AFHTTPResponseSerializer *)responseSerializer {
    responseSerializer.acceptableStatusCodes = _allStatusCodes;
    responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/plain", @"text/html", @"text/xml",@"image/*",@"application/x-www-form-urlencoded",nil];
}

/// 根据请求对象返回http请求编码器
/// @return http请求编码器
- (AFHTTPRequestSerializer *)getRequestSerializerForRequest:(HYZBaseRequest *)request {
    AFHTTPRequestSerializer *requestSerializer = nil;
    HYZRequestSerializerType serializerType = request.requestSerializerType;
    switch (serializerType) {
        case HYZRequestSerializerTypeJSON:
            requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        default: // 默认使用AFHTTPRequestSerializer格式的编码器
            requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
    }
    
    // 设置请求超时时间
    requestSerializer.timeoutInterval = [request requestTimeoutInterval];
    // 设置是否允许使用蜂窝连接
    requestSerializer.allowsCellularAccess = [request allowsCellularAccess];
    
    // 如果请求头中需要携带服务器所需要的用户账号和密码
    NSArray<NSString *> *authorizationHeaderFieldArray = [request requestAuthorizationHeaderFieldArray];
    if (authorizationHeaderFieldArray != nil) {
        if (authorizationHeaderFieldArray.count != 2) {
            [requestSerializer setAuthorizationHeaderFieldWithUsername:authorizationHeaderFieldArray.firstObject
            password:authorizationHeaderFieldArray.lastObject];
        } else {
            NSLog(@"requestAuthorizationHeaderFieldArray config error ...");
        }
    }

    // 如果有自定义的请求头参数
    NSDictionary<NSString *, NSString *> *headerFieldValueDictionary = [request requestHeaderFieldValueDictionary];
    if (headerFieldValueDictionary != nil) {
        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
            NSString *value = headerFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    
    return requestSerializer;
}

/// 创建请求对象中的会话接口任务
/// @param request 请求对象
/// @param error 会话创建过程中出现的错误
- (NSURLSessionTask *)sessionTaskForRequest:(HYZBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    
    // 请求方式
    HYZRequestMethod method = [request requestMethod];
    // 请求地址
    NSString *url = [request requestFullURLString];
    // 请求参数
    id param = [request requestParam];
    
    YZConstructingBlock constructingBlock = [request constructingBodyBlock];
    AFHTTPRequestSerializer *requestSerializer = [self getRequestSerializerForRequest:request];
    
    switch (method) {
        case HYZRequestMethodGet: {
            return [self dataTaskWithHTTPMethod:@"GET" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        }
            break;
        case HYZRequestMethodPOST: {
            return [self dataTaskWithHTTPMethod:@"POST" requestSerializer:requestSerializer URLString:url parameters:param constructingBodyWithBlock:constructingBlock error:error];
        }
            break;
        case HYZRequestMethodHEAD: {
            return [self dataTaskWithHTTPMethod:@"HEAD" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        }
            break;
        case HYZRequestMethodPUT: {
            return [self dataTaskWithHTTPMethod:@"PUT" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        }
            break;
        default:
            break;
    }
    
    return nil;
}

#pragma mark - 添加/取消请求对象

- (void)addRequest:(HYZBaseRequest *)request {
    NSCParameterAssert(request != nil);
    
    // 请求任务处理
    NSError * __autoreleasing requestSerializationError = nil;
    request.requestTask = [self sessionTaskForRequest:request error:&requestSerializationError];
    
    if (requestSerializationError != nil) {
        [self requestDidFailWithRequest:request error:requestSerializationError];
        return;
    }
    
    NSAssert(request.requestTask != nil, @"requestTask should not be nil");
    
    // Set request task priority
    if ([request.requestTask respondsToSelector:@selector(priority)]) {
        switch (request.requestPriority) {
            case HYZRequestPriorityHigh:
                request.requestTask.priority = NSURLSessionTaskPriorityHigh;
                break;
            case HYZRequestPriorityLow:
                request.requestTask.priority = NSURLSessionTaskPriorityLow;
                break;
            default:
                request.requestTask.priority = NSURLSessionTaskPriorityDefault;
                break;
        }
    }

    NSLog(@"Add request: %@", NSStringFromClass([request class]));
    [self addRequestToRecord:request];
    // 开启任务
    [request.requestTask resume];
}

- (void)cancelRequest:(HYZBaseRequest *)request {
    NSParameterAssert(request != nil);
    
    [request.requestTask cancel];
    [self removeRequestFromRecord:request];
    [request clearCompletionBlock];
}

- (void)cancelAllRequests {
    if (self.requestsRecordDictM.count <= 0) {
        return;
    }
    
    Lock();
    NSArray *allKeys = [self.requestsRecordDictM allKeys];
    Unlock();
    if (allKeys != nil && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            HYZBaseRequest *request = self.requestsRecordDictM[key];
            Unlock();
            // We are using non-recursive lock.
            // Do not lock `stop`, otherwise deadlock may occur.
            [request stopRequest];
        }
    }
}

/// 请求成功
/// @param request 请求对象
- (void)requestDidSucceedWithRequest:(HYZBaseRequest *)request {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 采用代理方式
        if (request.delegate != nil && [request.delegate respondsToSelector:@selector(didRequestFinished:)]) {
            [request.delegate didRequestFinished:request];
        }
        
        // 采用回调方式
        if (request.requestCompletionBlock != nil) {
            request.requestCompletionBlock(request);
        }
    });
}

/// 请求失败
/// @param request 请求对象
- (void)requestDidFailWithRequest:(HYZBaseRequest *)request error:(NSError *)error {
    request.error = error;
    NSLog(@"Request %@ failed, status code = %ld, error = %@",
           NSStringFromClass([request class]), (long)request.responseStatusCode, error.localizedDescription);
    dispatch_async(dispatch_get_main_queue(), ^{
        // 采用代理方式
        if (request.delegate != nil && [request.delegate respondsToSelector:@selector(didRequestFinished:)]) {
            [request.delegate didRequestFinished:request];
        }
        
        // 采用回调方式
        if (request.requestCompletionBlock != nil) {
            request.requestCompletionBlock(request);
        }
    });
}

/// 将一个请求对象添加到请求池中
/// @param request 请求对象
- (void)addRequestToRecord:(HYZBaseRequest *)request {
    if (request == nil) {
        return;
    }
    
    Lock();
    [self.requestsRecordDictM setObject:request forKey:@(request.requestTask.taskIdentifier)];
    Unlock();
}

/// 将一个请求对象从请求池中移除
/// @param request 请求对象
- (void)removeRequestFromRecord:(HYZBaseRequest *)request {
    if (request == nil) {
        return;
    }
    
    Lock();
    [self.requestsRecordDictM removeObjectForKey:@(request.requestTask.taskIdentifier)];
    Unlock();
}

#pragma mark - AFNetwork 处理块


/// 接口数据请求
/// @param method 请求方式
/// @param requestSerializer 请求编码器
/// @param URLString 请求地址
/// @param parameters 请求参数
/// @param error 接口请求所产生的错误信息
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                           error:(NSError * _Nullable __autoreleasing *)error {
    return [self dataTaskWithHTTPMethod:method requestSerializer:requestSerializer URLString:URLString parameters:parameters constructingBodyWithBlock:nil error:error];
}

/// 接口数据请求
/// @param method 请求方式
/// @param requestSerializer 请求编码器
/// @param URLString 请求地址
/// @param parameters 请求参数
/// @param block 多媒体构建体回调
/// @param error 接口请求所产生的错误信息
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                       constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                           error:(NSError * _Nullable __autoreleasing *)error {
    NSMutableURLRequest *request = nil;

    if (block) {
        request = [requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:block error:error];
    } else {
        request = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
    }

    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [self handleRequestResult:dataTask responseObject:responseObject error:error];
    }];

    return dataTask;
}

/// 请求结束后的结果处理
/// @param task 请求任务
/// @param responseObject 请求返回数据
/// @param error 请求产生的错误
- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error {
    if (task == nil || self.requestsRecordDictM.count <= 0) {
        return;
    }
    
    Lock();
    HYZBaseRequest *request = [self.requestsRecordDictM objectForKey:@(task.taskIdentifier)];
    Unlock();

    if (request == nil) {
        return;
    }

    NSLog(@"Finished Request: %@", NSStringFromClass([request class]));

    NSError * __autoreleasing serializationError = nil;
    NSError * __autoreleasing validationError = nil;

    NSError *requestError = nil;
    BOOL succeed = NO;

    request.responseObject = responseObject;
    if ([responseObject isKindOfClass:[NSData class]]) {
        request.responseString = [[NSString alloc] initWithData:responseObject encoding:[HYZNetworkUtils stringEncodingWithRequest:request]];

        switch (request.responseSerializerType) {
            case HYZResponseSerializerTypeHTTP:
                request.responseObject = [self.httpResponseSerializer responseObjectForResponse:task.response data:responseObject error:&serializationError];
                break;
            case HYZResponseSerializerTypeJSON:
                request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:task.response data:responseObject error:&serializationError];
                break;
            case HYZResponseSerializerTypeXMLParser:
                request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:task.response data:responseObject error:&serializationError];
                break;
            default:
                break;
        }
    }
    
    if (error != nil) {
        succeed = NO;
        requestError = error;
    } else if (serializationError != nil) {
        succeed = NO;
        requestError = serializationError;
    } else {
        succeed = [self validateResult:request error:&validationError];
        requestError = validationError;
    }

    if (succeed == YES) {
        [self requestDidSucceedWithRequest:request];
    } else {
        [self requestDidFailWithRequest:request error:requestError];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeRequestFromRecord:request];
        [request clearCompletionBlock];
    });
}

/// 检验获取到的数据是否是合法的
/// @param request 请求对象
/// @param error 不合法的错误信息
- (BOOL)validateResult:(HYZBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
// TODO data validate
    return YES;
}

#pragma mark - Getter

- (AFHTTPSessionManager *)manager {
    if (_manager == nil) {
        _manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:self.config.sessionConfiguration];
        _manager.securityPolicy = self.config.securityPolicy;
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        _allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        _manager.responseSerializer.acceptableStatusCodes = _allStatusCodes;
    }
    
    return _manager;
}

- (HYZNetworkConfig *)config {
    if (_config == nil) {
        _config = [HYZNetworkConfig sharedConfig];
    }
    
    return _config;
}

- (AFHTTPResponseSerializer *)httpResponseSerializer {
    if (_httpResponseSerializer == nil) {
        _httpResponseSerializer = [AFHTTPResponseSerializer serializer];
        [self handleResponseSerializerProperty:_httpResponseSerializer];
    }
    
    return _httpResponseSerializer;
}

- (AFJSONResponseSerializer *)jsonResponseSerializer {
    if (_jsonResponseSerializer == nil) {
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        [self handleResponseSerializerProperty:_jsonResponseSerializer];
    }
    
    return _jsonResponseSerializer;
}

- (AFXMLParserResponseSerializer *)xmlParserResponseSerialzier {
    if (_xmlParserResponseSerialzier == nil) {
        _xmlParserResponseSerialzier = [AFXMLParserResponseSerializer serializer];
        [self handleResponseSerializerProperty:_xmlParserResponseSerialzier];
    }
    return _xmlParserResponseSerialzier;
}

- (NSMutableDictionary <NSNumber *, HYZBaseRequest *> *)requestsRecordDictM {
    if (_requestsRecordDictM == nil) {
        _requestsRecordDictM = [NSMutableDictionary dictionaryWithCapacity:3];
    }
    
    return _requestsRecordDictM;
}

#pragma mark - Setter

@end
