//
//  AMBBaseBLController.m
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/4/29.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import "AMBBaseBLController.h"
#import "YTKRequest.h"
#import "AMBNetWorkConfig.h"
#import "NSObject+YYModel.h"

@interface AMBRequestQueryStringPair : NSObject

@property (nonatomic, strong) id field;
@property (nonatomic, strong) id value;

@end

@implementation AMBRequestQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value
{
    self = [super init];
    
    if (self)
    {
        self.field = field;
        self.value = value;
    }
    
    return self;
}

- (NSString *)urlEncodedStringValue
{
    if (!self.value || [self.value isEqual:[NSNull null]])
    {
        return [self urlEncodingByString:[self.field description]];
    }
    else
    {
        return [NSString stringWithFormat:@"%@=%@", [self urlEncodingByString:[self.field description]], [self urlEncodingByString:[self.value description]]];
    }
}

- (NSString *)urlEncodingByString:(NSString *)string
{
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@";
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];
    
    NSUInteger index = 0;
    static NSUInteger const batchSize = 50;
    NSMutableString *escaped = @"".mutableCopy;
    
    while (index < string.length)
    {
        NSUInteger length = MIN(string.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);
        range = [string rangeOfComposedCharacterSequencesForRange:range];
        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        index += range.length;
    }
    
    return escaped;
}

@end

#pragma mark -

@interface AMBPrivateRequest : YTKRequest

@property (nonatomic, strong) AMBBaseBLController *blController;

@end

@implementation AMBPrivateRequest

- (NSTimeInterval)requestTimeoutInterval
{
    return self.blController.requestTimeoutInterval;
}

- (NSDictionary<NSString *, NSString *> *)requestHeaderFieldValueDictionary
{
    NSMutableDictionary *headerDictionary = [NSMutableDictionary dictionary];
    
    if ([AMBNetWorkConfig sharedNetWorkConfig].globalRequestHeaderFieldValueDictionary.count > 0)
    {
        [headerDictionary addEntriesFromDictionary:[AMBNetWorkConfig sharedNetWorkConfig].globalRequestHeaderFieldValueDictionary];
    }
    
    if (self.blController.requestHeaderFieldValueDictionary.count > 0)
    {
        [headerDictionary addEntriesFromDictionary:self.blController.requestHeaderFieldValueDictionary];
    }
    
    return headerDictionary;
}

- (NSString *)requestUrl
{
    return self.blController.requestUrl;
}

- (id)requestArgument
{
    return [self.blController.paramObject yy_modelToJSONObject];
}

- (YTKRequestMethod)requestMethod
{
    YTKRequestMethod requestMethod;
    
    switch (self.blController.requestMethod)
    {
        case AMBRequestMothodGET:
            requestMethod = YTKRequestMethodGET;
            break;
            
        case AMBRequestMothodPOST:
            requestMethod = YTKRequestMethodPOST;
            break;
            
        case AMBRequestMothodHEAD:
            requestMethod = YTKRequestMethodHEAD;
            break;
            
        case AMBRequestMothodPUT:
            requestMethod = YTKRequestMethodPUT;
            break;
            
        case AMBRequestMothodDELETE:
            requestMethod = YTKRequestMethodDELETE;
            break;
            
        case AMBRequestMothodPATCH:
            requestMethod = YTKRequestMethodPATCH;
            break;
            
        default:
            requestMethod = YTKRequestMethodGET;
            break;
    }
    
    return requestMethod;
}

- (YTKRequestSerializerType)requestSerializerType
{
    YTKRequestSerializerType requestSerializerType;
    
    switch (self.blController.requestSerializerType)
    {
        case AMBRequestSerializerTypeHTTP:
            requestSerializerType = YTKRequestSerializerTypeHTTP;
            break;
            
        case AMBRequestSerializerTypeJSON:
            requestSerializerType = YTKRequestSerializerTypeJSON;
            break;
            
        default:
            requestSerializerType = YTKRequestSerializerTypeHTTP;
            break;
    }
    
    return requestSerializerType;
}

- (YTKResponseSerializerType)responseSerializerType
{
    YTKResponseSerializerType responseSerializerType;
    
    switch (self.blController.responseSerializerType)
    {
        case AMBResponseSerializerTypeHTTP:
            responseSerializerType = YTKResponseSerializerTypeHTTP;
            break;
            
        case AMBResponseSerializerTypeJSON:
            responseSerializerType = YTKResponseSerializerTypeJSON;
            break;
            
        case AMBResponseSerializerTypeXMLParser:
            responseSerializerType = YTKResponseSerializerTypeXMLParser;
            break;
            
        default:
            responseSerializerType = YTKResponseSerializerTypeHTTP;
            break;
    }
    
    return responseSerializerType;
}

- (AFConstructingBlock)constructingBodyBlock
{
    return (AFConstructingBlock)(self.blController.constructingBodyBlock);
}

- (AFURLSessionTaskProgressBlock)resumableDownloadProgressBlock
{
    return (AFURLSessionTaskProgressBlock)(self.blController.resumableDownloadProgressBlock);
}

- (NSURLRequest *)buildCustomUrlRequest
{
    return self.blController.customUrlRequest;
}

@end

#pragma mark -

@interface AMBBaseBLController ()

@property (nonatomic, copy) NSString *requestUrl;
@property (nonatomic, strong) NSObject *paramObject;
@property (nonatomic, strong) AMBPrivateRequest *httpRequest;
@property (nonatomic, copy) AMBRequestCompletionBlock successBlock;
@property (nonatomic, copy) AMBRequestCompletionBlock failureBlock;
@property (nonatomic, assign) NSInteger responseStatusCode;
@property (nonatomic, copy) NSString *responseString;

@end

@implementation AMBBaseBLController

#pragma mark -
#pragma mark ==== 系统方法 ====
#pragma mark -

- (void)dealloc
{
    _successBlock = nil;
    _failureBlock = nil;
    _httpRequest.blController = nil;
    _httpRequest = nil;
    _error = nil;
    
#if DEBUG
    NSLog(@"%@接口请求实例释放，实例内存地址:<%p>", NSStringFromClass([self class]), self);
#endif
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.requestTimeoutInterval = 30;
        self.requestMethod = AMBRequestMothodGET;
        self.requestSerializerType = AMBRequestSerializerTypeHTTP;
        self.responseSerializerType = AMBResponseSerializerTypeJSON;
        
#if DEBUG
    NSLog(@"%@接口请求实例创建，实例内存地址:<%p>", NSStringFromClass([self class]), self);
#endif
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    AMBBaseBLController *blController = [[self class] new];
    blController.baseUrl = self.baseUrl;
    blController.version = self.version;
    blController.path = self.path;
    blController.requestTimeoutInterval = self.requestTimeoutInterval;
    blController.requestMethod = self.requestMethod;
    blController.requestSerializerType = self.requestSerializerType;
    blController.responseSerializerType = self.responseSerializerType;
    blController.customUrlRequest = self.customUrlRequest;
    blController.requestHeaderFieldValueDictionary = self.requestHeaderFieldValueDictionary;
    blController.paramObject = self.paramObject;
    blController.getParamObject = self.getParamObject;
    blController.dataModelClass = self.dataModelClass;
    
    blController.constructingBodyBlock = self.constructingBodyBlock;
    blController.resumableDownloadPath = self.resumableDownloadPath;
    blController.resumableDownloadProgressBlock = self.resumableDownloadProgressBlock;
    return blController;
}

#pragma mark -
#pragma mark ==== 外部使用方法 ====
#pragma mark -

/**
 根据给定参数实体初始化接口请求类
 
 @param paramObject 传递的参数
 @return 返回接口请求类
 */
- (instancetype)initWithParam:(NSObject *)paramObject
{
    self = [self init];
    
    if (self)
    {
        self.paramObject = paramObject;
    }
    
    return self;
}

/**
 设置成功和失败的回调并开始接口请求
 
 @param successBlock 请求成功的回调
 @param failureBlock 请求失败的回调
 */
- (void)startWithCompletionBlockWithSuccess:(AMBRequestCompletionBlock)successBlock failure:(AMBRequestCompletionBlock)failureBlock
{
#if DEBUG
    if (self.requestMethod == AMBRequestMothodPOST && self.getParamObject)
    {
        NSLog(@"开始接口请求，实例内存地址:%p，接口地址:%@，get传递参数:%@，post传递参数%@", self, self.requestUrl, [self.getParamObject yy_modelToJSONObject], [self.paramObject yy_modelToJSONObject]);
    }
    else
    {
        NSLog(@"开始接口请求，实例内存地址:%p，接口地址:%@，传递参数:%@", self, self.requestUrl, [self.paramObject yy_modelToJSONObject]);
    }
#endif
    
     __weak __typeof(self) weakSelf = self;
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    
    [self.httpRequest startWithCompletionBlockWithSuccess:^(YTKBaseRequest *request) {
        
        [weakSelf getInterfaceRequestData:request];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            id responseData = weakSelf.responseSerializerType == AMBResponseSerializerTypeHTTP ? request.responseString : request.responseObject;
            
            if ([weakSelf parseResponseData:responseData])
            {
                [weakSelf requestSuccess];
            }
            else
            {
                [weakSelf requestFail];
            }
        });
    } failure:^(YTKBaseRequest *request) {
        
        [weakSelf getInterfaceRequestData:request];
        [weakSelf requestFail];
    }];
}

/**
 解析成实体类型数据，默认返回YES
 
 @param responseObject 接口请求返回的数据(AMBResponseSerializerTypeHTTP样式时为json字符串，AMBResponseSerializerTypeJSON样式时为json object，AMBResponseSerializerTypeXMLParser样式时为NSXMLParser类型数据)
 @return 解析成实体类型数据，成功为YES，失败为NO
 */
- (BOOL)parseResponseData:(id)responseObject
{
    return YES;
}

/**
 取消接口请求
 */
- (void)cancelRequest
{
    if (_httpRequest)
    {
        [_httpRequest stop];
    }
    
    _successBlock = nil;
    _failureBlock = nil;
    _httpRequest.blController = nil;
    _httpRequest = nil;
    _error = nil;
}

#pragma mark -
#pragma mark ==== 内部使用方法 ====
#pragma mark -

/**
 请求成功回调
 */
- (void)requestSuccess
{
#if DEBUG
    NSLog(@"接口请求成功，实例内存地址:%p，接口地址:%@，返回数据:%@", self, self.requestUrl, self.httpRequest.responseString);
#endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(blControllerFinished:)])
        {
            [self.delegate blControllerFinished:self];
        }
        
        if (self.successBlock)
        {
            self.successBlock(self);
        }
        
        [self clearConfig];
    });
}

/**
 请求失败回调
 */
- (void)requestFail
{
#if DEBUG
    NSLog(@"接口请求失败，实例内存地址:%p，接口地址:%@，返回数据:%@", self, self.requestUrl, self.httpRequest.responseString);
#endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(blControllerFailed:)])
        {
            [self.delegate blControllerFailed:self];
        }
        
        if (self.failureBlock)
        {
            self.failureBlock(self);
        }
        
        [self clearConfig];
    });
}

/**
 获取接口请求返回来的数据

 @param request 请求实例
 */
- (void)getInterfaceRequestData:(YTKBaseRequest *)request
{
    self.responseStatusCode = request.responseStatusCode;
    self.responseString = request.responseString;
}

/**
 清理配置
 */
- (void)clearConfig
{
    dispatch_async(dispatch_get_main_queue(), ^{
       
        _successBlock = nil;
        _failureBlock = nil;
        _httpRequest.blController = nil;
        _httpRequest = nil;
        _error = nil;
    });
}

/**
 生成参数字符串
 
 @param dictionary 参数字典
 @return 参数字符串
 */
- (NSString *)queryStringFromDictionary:(NSDictionary *)dictionary
{
    NSMutableArray *paramStringArray = [NSMutableArray array];
    
    for (AMBRequestQueryStringPair *pair in [self queryStringPairsWithKey:nil value:dictionary])
    {
        [paramStringArray addObject:[pair urlEncodedStringValue]];
    }
    
    return [paramStringArray componentsJoinedByString:@"&"];
}

/**
 生成AMBRequestQueryStringPair实例数组
 
 @param key key
 @param value value
 @return AMBRequestQueryStringPair实例数组
 */
- (NSArray *)queryStringPairsWithKey:(NSString *)key value:(id)value
{
    NSMutableArray *pairsArray = [NSMutableArray array];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    
    if ([value isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dictionary = value;
        
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[sortDescriptor]])
        {
            id nestedValue = dictionary[nestedKey];
            
            if (nestedValue)
            {
                [pairsArray addObjectsFromArray:[self queryStringPairsWithKey:(key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey) value:nestedValue]];
            }
        }
    }
    else if ([value isKindOfClass:[NSArray class]])
    {
        NSArray *array = value;
        
        for (id nestedValue in array)
        {
            [pairsArray addObjectsFromArray:[self queryStringPairsWithKey:[NSString stringWithFormat:@"%@[]", key] value:nestedValue]];
        }
    }
    else if ([value isKindOfClass:[NSSet class]])
    {
        NSSet *set = value;
        
        for (id object in [set sortedArrayUsingDescriptors:@[sortDescriptor]])
        {
            [pairsArray addObjectsFromArray:[self queryStringPairsWithKey:key value:object]];
        }
    }
    else
    {
        [pairsArray addObject:[[AMBRequestQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return pairsArray;
}

#pragma mark -
#pragma mark ==== 数据初始化 ====
#pragma mark -

- (NSString *)requestUrl
{
    if (!_requestUrl)
    {
        //若是自己有设置基础url，则以自己的基础url为准，若没有，则以公用的基础url为准
        if (self.baseUrl.length > 0)
        {
            _requestUrl = [self.baseUrl stringByAppendingPathComponent:self.version.length > 0 ? self.version : @""];
            _requestUrl = [_requestUrl stringByAppendingPathComponent:self.path];
        }
        else
        {
            if ([AMBNetWorkConfig sharedNetWorkConfig].baseUrl.length > 0)
            {
                //若是自己有设置版本号，则以自己的版本号为准，若没有，则以公用的版本号为准
                NSString *version = self.version.length > 0 ? self.version : [AMBNetWorkConfig sharedNetWorkConfig].version;
                _requestUrl = [[AMBNetWorkConfig sharedNetWorkConfig].baseUrl stringByAppendingPathComponent:version.length > 0 ? version : @""];
                _requestUrl = [_requestUrl stringByAppendingPathComponent:self.path];
            }
            else
            {
                [NSException raise:NSInvalidArgumentException format:@"实例内存地址:%p，基础url不能为空", self];
            }
        }
        
        //若为AMBRequestMothodPOST方式且有get方式传递的数据，就将其拼接到url上
        if (self.requestMethod == AMBRequestMothodPOST && self.getParamObject)
        {
            NSString *getParam = [self queryStringFromDictionary:[self.getParamObject yy_modelToJSONObject]];
            
            if (getParam.length > 0)
            {
                _requestUrl = [_requestUrl stringByAppendingFormat:[_requestUrl containsString:@"?"] ? @"&%@" : @"?%@", getParam];
            }
        }
    }
    
    return _requestUrl;
}

- (AMBPrivateRequest *)httpRequest
{
    if (!_httpRequest)
    {
        _httpRequest = [[AMBPrivateRequest alloc] init];
        _httpRequest.blController = self;//此处强引用一次，待接口请求完成会置空
    }
    
    return _httpRequest;
}

@end
