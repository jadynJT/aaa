//
//  AMBBaseBLController.h
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/4/29.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMBBaseBLController;
@protocol AFMultipartFormData;

/**
 网络请求方法类型
 */
typedef NS_ENUM(NSInteger, AMBRequestMothod)
{
    AMBRequestMothodGET,
    AMBRequestMothodPOST,
    AMBRequestMothodHEAD,
    AMBRequestMothodPUT,
    AMBRequestMothodDELETE,
    AMBRequestMothodPATCH,
};

/**
 请求参数序列化类型
 */
typedef NS_ENUM(NSInteger, AMBRequestSerializerType)
{
    AMBRequestSerializerTypeHTTP,
    AMBRequestSerializerTypeJSON,
};

/**
 响应数据序列化类型
 */
typedef NS_ENUM(NSInteger, AMBResponseSerializerType)
{
    AMBResponseSerializerTypeHTTP,
    AMBResponseSerializerTypeJSON,
    AMBResponseSerializerTypeXMLParser,
};

/**
 AMBBaseBLController类的代理
 */
@protocol AMBBaseBLControllerDelegate <NSObject>

@optional

/**
 请求成功的回调方法
 
 @param blController AMBBaseBLController实例
 */
- (void)blControllerFinished:(AMBBaseBLController *)blController;

/**
 请求失败的回调方法
 
 @param blController AMBBaseBLController实例
 */
- (void)blControllerFailed:(AMBBaseBLController *)blController;

@end

/**
 用于上传文件的协议
 */
@protocol AMBMultipartFormData <AFMultipartFormData>

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name error:(NSError * _Nullable __autoreleasing *)error;

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType error:(NSError * _Nullable __autoreleasing *)error;

- (void)appendPartWithInputStream:(nullable NSInputStream *)inputStream name:(NSString *)name fileName:(NSString *)fileName length:(int64_t)length mimeType:(NSString *)mimeType;

- (void)appendPartWithFileData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

- (void)appendPartWithFormData:(NSData *)data name:(NSString *)name;

- (void)appendPartWithHeaders:(nullable NSDictionary <NSString *, NSString *> *)headers body:(NSData *)body;

- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes delay:(NSTimeInterval)delay;

@end

typedef void (^AMBConstructingBlock)(id<AMBMultipartFormData> formData);
typedef void (^AMBURLSessionTaskProgressBlock)(NSProgress *progress);
typedef void (^AMBRequestCompletionBlock)(AMBBaseBLController *blController);

/**
 接口请求基类
 */
@interface AMBBaseBLController : NSObject<NSCopying>
{
    NSString *_baseUrl;
    NSString *_version;
    NSString *_path;
    NSTimeInterval _requestTimeoutInterval;
    AMBRequestMothod _requestMethod;
    AMBRequestSerializerType _requestSerializerType;
    AMBResponseSerializerType _responseSerializerType;
    NSURLRequest *_customUrlRequest;
    NSDictionary<NSString *, NSString *> *_requestHeaderFieldValueDictionary;
    NSObject *_getParamObject;
    Class _dataModelClass;
    
    AMBConstructingBlock _constructingBodyBlock;
    NSString *_resumableDownloadPath;
    AMBURLSessionTaskProgressBlock _resumableDownloadProgressBlock;
}

/*************************************************************************/
/***************************以下属性用于设置接口请求***************************/
/*************************************************************************/

/**
 代理
 */
@property (nonatomic, weak) id<AMBBaseBLControllerDelegate> delegate;

/**
 基础url
 */
@property (nonatomic, copy) NSString *baseUrl;

/**
 接口版本号
 */
@property (nonatomic, copy) NSString *version;

/**
 接口路径
 */
@property (nonatomic, copy) NSString *path;

/**
 完整接口地址，由bseUrl、version、path拼接而成(拼接时：1、若自己设置了baseUrl，则baseUrl跟version都以自己的为准；2、若自己没有设置baseUrl有设置version，则baseUrl以公用的为准，version以自己的为准；3、若自己没有设置baseUrl也没有设置version，则baseUrl跟version都以公用的为准)
 */
@property (nonatomic, copy, readonly) NSString *requestUrl;

/**
 超时时间，默认为30s
 */
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

/**
 网络请求方法类型，默认为AMBRequestMothodGET
 */
@property (nonatomic, assign) AMBRequestMothod requestMethod;

/**
 请求参数序列化类型，默认为AMBRequestSerializerTypeHTTP
 */
@property (nonatomic, assign) AMBRequestSerializerType requestSerializerType;

/**
 响应数据序列化类型，默认为AMBResponseSerializerTypeJSON
 */
@property (nonatomic, assign) AMBResponseSerializerType responseSerializerType;

/**
 自定义NSURLRequest，默认为nil(除非需要自定义，否则不要去设置该属性)
 */
@property (nonatomic, strong) NSURLRequest *customUrlRequest;

/**
 请求头数据，默认为nil
 */
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *requestHeaderFieldValueDictionary;

/**
 请求参数，默认为nil
 */
@property (nonatomic, strong, readonly) NSObject *paramObject;

/**
 请求参数，默认为nil。(该参数仅限于AMBRequestMothodPOST方式时，部分参数要用get方式传递，部分参数要用post方式传递时使用。那部分要用get方式传递的参数放到该实体属性来，会自动拼接到requestUrl属性上)
 */
@property (nonatomic, strong) NSObject *getParamObject;

/**
 实体的class，默认为NULL
 */
@property (nonatomic, assign) Class dataModelClass;

/***************************************************************************/
/***************************以下属性为接口请求返回数据***************************/
/***************************************************************************/

@property (nonatomic, assign, readonly) NSInteger responseStatusCode;
@property (nonatomic, copy, readonly) NSString *responseString;
@property (nonatomic, strong) NSError *error;

/***************************************************************************/
/******************************以下属性用于上传文件*****************************/
/***************************************************************************/

/**
 添加上传文件的回调
 */
@property (nonatomic, copy) AMBConstructingBlock constructingBodyBlock;

/***************************************************************************/
/******************************以下属性用于下载文件*****************************/
/***************************************************************************/

/**
 下载文件的存储路径
 */
@property (nonatomic, copy) NSString *resumableDownloadPath;

/**
 文件下载的进度回调
 */
@property (nonatomic, copy) AMBURLSessionTaskProgressBlock resumableDownloadProgressBlock;

/***************************************************************************/
/**********************************以下为方法*********************************/
/***************************************************************************/

/**
 根据给定参数实体初始化接口请求类
 
 @param paramObject 传递的参数
 @return 返回接口请求类
 */
- (instancetype)initWithParam:(NSObject *)paramObject;

/**
 设置成功和失败的回调并开始接口请求
 
 @param successBlock 请求成功的回调
 @param failureBlock 请求失败的回调
 */
- (void)startWithCompletionBlockWithSuccess:(AMBRequestCompletionBlock)successBlock failure:(AMBRequestCompletionBlock)failureBlock;

/**
 解析成实体类型数据，默认返回YES
 
 @param responseObject 接口请求返回的数据(AMBResponseSerializerTypeHTTP样式时为json字符串，AMBResponseSerializerTypeJSON样式时为json object，AMBResponseSerializerTypeXMLParser样式时为NSXMLParser类型数据)
 @return 解析成实体类型数据，成功为YES，失败为NO
 */
- (BOOL)parseResponseData:(id)responseObject;

/**
 取消接口请求
 */
- (void)cancelRequest;

@end
