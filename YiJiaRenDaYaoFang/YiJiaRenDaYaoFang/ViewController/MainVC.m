
//  MainVC.m
//  YueYaoWang
//
//  Created by apple on 16/1/20.
//  Copyright © 2016年 TW. All rights reserved.
//

#import "MainVC.h"
#import "WXAuthor.h"
#import "iPhoneInfo.h"
#import "ACETelPrompt.h"
#import "SVProgressHUD.h"
#import "UserGuidenIntroView.h"
#import "AFNetworking.h"
#import "NSString+Utils.h"
#import "NSTimer+Extention.h"
#import "LocationManager.h"
#import "TWUpdateAppVersion.h"
#import "GradualProgressView.h"
#import "TWBaseNavigationController.h"
#import "ScanLifeLoginViewController.h"
#import "UINavigationController+FDFullscreenPopGesture.h"
#import "LinkSkipViewController.h"
#import "TopView.h"
#import "WXShare.h"
#import <MapKit/MapKit.h>
#import <Contacts/Contacts.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AddressBook/AddressBook.h>
#import <NSData+AMBAdd.h>

@interface MainVC ()<UIWebViewDelegate,WKNavigationDelegate,WKUIDelegate,QRCodeReaderDelegate,WXApiDelegate,BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate,CLLocationManagerDelegate,MAMapViewDelegate,AMapLocationManagerDelegate>

@property (strong, nonatomic) QqcWebView *webView;
@property (strong, nonatomic) QqcWebViewJavascriptBridge bridge;
@property (strong, nonatomic) GradualProgressView *bgGProgressView;

@property (strong, nonatomic) BMKGeoCodeSearch *geocodesearch; // 地理编码主类，用来查询、返回结果信息
@property (strong, nonatomic) BMKLocationService *locService;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geocoder; // 地理编码、反地理编码工具类

//@property (nonatomic, strong) AMapLocationManager *locationManager;

@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UIImageView *bgImgView;
@property (strong, nonatomic) NSString *userAgent;

@property (strong, nonatomic) UIButton *countdownBtn;    // 倒计时按钮
@property (strong, nonatomic) NSTimer *timer;            // 计时器
@property (strong, nonatomic) NSTimer *timeout;          // 超时计时器
@property (assign, nonatomic) BOOL isFirstLoad;          // 是否第一次加载
@property (assign, nonatomic) BOOL isCheckVersion;       // 检查版本
@property (assign, nonatomic) BOOL isDispalyTopView;
@property (assign, nonatomic) BOOL isReloadCart;

@property (strong, nonatomic) ScanLifeLoginViewController *scanLifeLoginVC; // 二维码登录界面
@property (strong, nonatomic) QRCodeReaderViewController *QRCodeVC;         // 扫码控制器

@property (strong, nonatomic) QRCodeReaderViewController *reader;
@property (strong, nonatomic) TopView *topView;

@property (copy, nonatomic) NSString *isSaved;
@property (copy, nonatomic) NSString *hostName;  // URL地址
@property (copy, nonatomic) NSString *latitude;  // 纬度
@property (copy, nonatomic) NSString *longitude; // 经度

@property (strong, nonatomic) NSMutableDictionary *cacheDict;

@end

@implementation MainVC

- (ScanLifeLoginViewController *)scanLifeLoginVC {
    if (!_scanLifeLoginVC) {
        self.scanLifeLoginVC = [[ScanLifeLoginViewController alloc] init];
    }
    return _scanLifeLoginVC;
}

/** 传入控制器、url、标题 */
+ (void)showWithContro:(UIViewController *)contro {
    MainVC *vc = [MainVC new];
    UIWindow *window = [[[UIApplication sharedApplication]delegate]window];
    window.rootViewController=vc;
}

- (void)dealloc {
    _bgGProgressView = nil;
    _webView = nil;
    _bridge = nil;
    _bgImgView = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([_isSaved isEqualToString:@"0"]) {
        if ([_webView isKindOfClass:[UIWebView class]]) {
            [(UIWebView *)_webView reload];
        }else if ([_webView isKindOfClass:[WKWebView class]]) {
            [(WKWebView *)_webView reload];
        }
    }
    
    //隐藏导航栏
    [self.navigationController setNavigationBarHidden:YES];
}

-(void)viewWillDisappear:(BOOL)animated {
    _locService.delegate = nil;
    _geocodesearch.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configProgress]; // 进度条
    
    [self configBgView]; // 显示蒙版
    
    [self regJSApi]; // 注册JS交互
    
    [self onResp];  // 分享、登录的回调
    
//    [self configWebView];  // 加载webview
    
//    [self configUserAgent:self.webView]; // 标识符
    
//    [self startLocation]; // 开始定位
}

#pragma mark - 初始化
- (QqcWebView *)webView {
    if (nil == _webView) {
        if (NSClassFromString(@"WKWebView")) {
            if (iphoneX) {
                _webView = (QqcWebView*)[[WKWebView alloc] initWithFrame:CGRectMake(0, 44, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height-44-34)];
            }else {
                _webView = (QqcWebView*)[[WKWebView alloc] initWithFrame:CGRectMake(0, 0, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height)];
            }
            
            if (@available(iOS 11.0, *))
            {//  防止无导航栏时顶部出现44高度的空白 (适配iPhone X)
                ((WKWebView *)_webView).scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
            [_webView allowDisplayingKeyboardWithoutUserAction]; // 唤起键盘
//             ((WKWebView *)_webView).allowsBackForwardNavigationGestures = YES; // 开启侧滑返回上一页
//            [_webView wkWebViewShowKeybord]; // 唤起键盘
        }
        else {
            _webView = (QqcWebView*)[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height)];
//            ((UIWebView *)_webView).keyboardDisplayRequiresUserAction = NO;
        }
        [self.view insertSubview:_webView belowSubview:_progressView];
    }
    return _webView;
}

- (id)bridge {
    if (nil == _bridge)
    {
        if ([self.webView isKindOfClass:[UIWebView class]])
        {
            _bridge = [WebViewJavascriptBridge bridgeForWebView:(UIWebView*)self.webView];
            [(WebViewJavascriptBridge *)_bridge setWebViewDelegate:self];
        }
        else if ([self.webView isKindOfClass:[WKWebView class]])
        {
            _bridge = [WKWebViewJavascriptBridge bridgeForWebView:(WKWebView*)self.webView];
            [(WebViewJavascriptBridge *)_bridge setWebViewDelegate:self];
        }
    }
    return _bridge;
}

- (TopView *)topView {
    if (!_topView) {
        CGFloat marginY = 0;
        if (iphoneX) marginY = 44;
        
        self.topView = [[TopView alloc] initWithFrame:CGRectMake(0, marginY, Screen_width, 44)];
        self.topView.backgroundColor = [UIColor whiteColor];
        self.topView.hidden = YES;
        
        __weak typeof(self) weakself = self;
        self.topView.returnBlock = ^{
            if ([((WKWebView *)weakself.webView) canGoBack]) {
                [((WKWebView *)weakself.webView) goBack];
            }
        };
    }
    return _topView;
}

- (CLGeocoder *)geocoder {
    if (!_geocoder) {
        self.geocoder = [[CLGeocoder alloc] init];
    }
    return _geocoder;
}

#pragma mark - 注册JS接口
- (void)regJSApi {
    //调用扫码方法
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"scancode" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        NSLog(@"%s 扫码被触发", __FUNCTION__);
        [self scannerClick];
    }];
    
    //调用分享方法
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"wxsharedcode" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        NSLog(@"%s 分享被触发", __FUNCTION__);
        NSLog(@"data===%@",data);
        [self wxCircleClick:data];
    }];

    //分享小程序
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"wxminprogramcode" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        NSLog(@"%s 小程序分享被触发", __FUNCTION__);
        NSLog(@"小程序data===%@",data);
        [self wxWinProgramClick:data];
    }];
    
    //测量页面
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"measureCode" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        NSLog(@"%s 完善会员资料页面被触发", __FUNCTION__);
        NSLog(@"测量data=====  %@",data);
        [self gotoMeasurePage:data];
    }];

    //会员搜索页面
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"memberSearchCode" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        NSLog(@"%s 会员搜索页面被触发", __FUNCTION__);
        [self gotoSearchVC:data];
    }];

    //退出登录 清理缓存
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"loginOutCode" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        NSLog(@"%s 清理缓存被触发", __FUNCTION__);
        [self loginOutAction];
    }];

    //微信登录
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"wxlogincode" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        NSLog(@"%s 微信登录", __FUNCTION__);
        NSLog(@"wxLoginData===%@",data);
        [WXAuthor shareInstance].viewcontroller = self;
        [[WXAuthor shareInstance] WeChatOAuth:WX_APPKEY];
    }];

    //微信支付
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"wxPayhandle" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        NSLog(@"%s 微信支付", __FUNCTION__);
        NSLog(@"wxLoginData===%@",data);
        if (![[WXAuthor shareInstance] isWXAppInstalled]) {
            [NSString alert:@"您未安装微信客户端"]; // 弹框提醒
        }else {
            [[WXAuthor shareInstance] wechatPay:data];
        }
    }];

    //清除缓存
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"removeCache" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        [self removeCache];
    }];
    
    //经纬度
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"getLngLat" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        [self startLocation];
//        [self configLocationManager];
    }];

    //读取通讯录
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"setContact" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        [self getAuthor];
    }];
    
    //写入缓存
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"setCache" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        self.cacheDict = (NSMutableDictionary *)data;
        NSLog(@"self.cacheDict = %@",self.cacheDict);
//        self.cacheDict = [NSMutableDictionary getObjectData:data];
    }];

    //读取缓存
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"getCache" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        responseCallback(self.cacheDict);
    }];

    // 打开应用设置
    [Utility webViewJavascriptBridge:self.bridge handlerName:@"openSetting" webViewJSCallBlock:^(id data, WVJBResponseCallback responseCallback){
        NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [self openUrl:url showOpenFailTip:NO];
    }];
}

#pragma mark - configMethod
- (void)configWebView:(NSString *)webUrl {
    [self.webView loadRequestWithString:webUrl];
    [_webView setScalesPageToFit:NO];
    _webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = NO;
    
    [self.view addSubview:self.topView]; // 设置顶部视图
}

#pragma mark - 清理webView缓存
- (void)removeCache {
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }else {
        if ([[[UIDevice currentDevice] systemVersion] intValue] > 8) {
            NSArray *types = @[WKWebsiteDataTypeMemoryCache,WKWebsiteDataTypeDiskCache];
            NSSet *websiteDataTypes = [NSSet setWithArray:types];
            NSDate *dateForm = [NSDate dateWithTimeIntervalSince1970:0];
            [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateForm completionHandler:^{
            }];
        }else
        {
            NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *cookiesFolderPath = [libraryPath stringByAppendingString:@"/Cookies"];
            NSError *errors;
            [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&errors];
        }
    }
}

- (void)configUserAgent:(QqcWebView *)webView {
    if ([self.userAgent rangeOfString:@"TWAPP"].location!=NSNotFound) {
        NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
        
        if ([webView isKindOfClass:[UIWebView class]]) {
            UIWebView *webview = [[UIWebView alloc]initWithFrame:CGRectZero];
            [webview evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
                NSString *userAgent = result;
                
                NSString *newUserAgent = [userAgent stringByAppendingString:[NSString stringWithFormat:@" TWAPP:%@/ipa",version]];
                NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:newUserAgent, @"UserAgent", nil];
                [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
            }];
        }else if ([webView isKindOfClass:[WKWebView class]]){
            [webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
                NSString *userAgent = result;
                
                NSString *newUserAgent = [userAgent stringByAppendingString:[NSString stringWithFormat:@" TWAPP:%@/ipa",version]];
                
                NSLog(@"newUserAgent = %@",newUserAgent);
                
                if([webView isKindOfClass:[WKWebView class]]){
                    [webView setValue:newUserAgent forKey:@"applicationNameForUserAgent"];
                }
            }];
        }
    }
}

#pragma mark - 配置背景图片
- (void)configBgView {
    self.bgImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height)];
    
    NSString * key = [NSString stringWithFormat:@"%dx%d", (int)Screen_width, (int)Screen_height];
    
    if (IS_SCREEN_61_INCH && [key isEqualToString:@"414x896"]) { // 为iPhoneXR
        self.bgImgView.image = [UIImage imageNamed:@"LaunchImage-1200-Portrait-1792h"];
    }else {
        self.bgImgView.image = [UIImage imageNamed:[Utility lanchImageInch:key]];
    }
    
    self.bgImgView.userInteractionEnabled = YES;
    [self.view addSubview:self.bgImgView];
    
    [self congigBgCountDownBtn]; // 倒计时按钮
    
    self.cacheDict = [NSMutableDictionary dictionary];
//    [self.cacheDict setValue:@(1) forKey:@"locationCache"];
    
    __weak typeof(self) weakself = self;
    // 跳转计时器
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES limitCount:5 countdownCallback:^(NSUInteger countdown){
        [weakself.countdownBtn setTitle:[NSString stringWithFormat:@"跳过%ld",5-(long)countdown] forState:0];
    } timerEndCallback:^{
        [weakself hiddenSkipBtn];
    }];
    
    // 超时计时器
    self.timeout = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES limitCount:8 countdownCallback:^(NSUInteger countdown){
    } timerEndCallback:^{
        // 加载后会执行 didFinishNavigation 代理方法
        Utility *utility = [[Utility alloc] init];
        [utility onTimeOutAction:((WKWebView*)weakself.webView)];
//        [((WKWebView*)weakself.webView) stopLoading];
    }];
}

- (void)congigBgCountDownBtn {
    // 倒计时按钮
    CGFloat topOrigin = 25;
    if (iphoneX) topOrigin = 35;
    self.countdownBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.countdownBtn.frame = CGRectMake(Screen_width-60-20, topOrigin, 60, 30);
    self.countdownBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    [self.countdownBtn setTitleColor:[UIColor whiteColor] forState:0];
    self.countdownBtn.layer.cornerRadius = 5.0;
    self.countdownBtn.layer.masksToBounds = YES;
    [self.countdownBtn setTitle:@"跳过5" forState:0];
    self.countdownBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.bgImgView addSubview:self.countdownBtn];
    [self.countdownBtn addTarget:self action:@selector(hiddenSkipBtn) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configProgress {
    // 进度条
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    
    CGFloat topMargin = 0;
    if (iphoneX) topMargin = 44;
    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, topMargin, Screen_width, 0)];
    progressView.tintColor = [UIColor orangeColor];
    progressView.trackTintColor = [UIColor whiteColor];
    [self.view addSubview:progressView];
    self.progressView = progressView;
}

#pragma mark - KVO的监听代理
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.webView && [keyPath isEqualToString:@"estimatedProgress"])
    {// 获取网页加载进度
        CGFloat newprogress = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        self.progressView.alpha = 1.0f;
        [self.progressView setProgress:newprogress animated:YES];
        if (newprogress >= 1.0f) {
            [UIView animateWithDuration:0.3f
                                  delay:0.3f
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 self.progressView.alpha = 0.0f;
                             }
                             completion:^(BOOL finished) {
                                 [self.progressView setProgress:0 animated:NO];
                             }];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - 定位
- (void)startLocation {
    NSLog(@"进入普通定位态");
    self.locService = [[BMKLocationService alloc] init];
    self.locService.desiredAccuracy = kCLLocationAccuracyBest;
    self.locService.delegate = self;
    [self.locService startUserLocationService];
    self.geocodesearch = [[BMKGeoCodeSearch alloc] init];
    self.geocodesearch.delegate = self;
}

//- (void)configLocationManager {
//    self.locationManager = [[AMapLocationManager alloc] init];
//
//    [self.locationManager setDelegate:self];
//
//    self.locationManager.distanceFilter = 5;
//
//    //设置不允许系统暂停定位
//    [self.locationManager setPausesLocationUpdatesAutomatically:NO];
//
//    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
//
//    //设置允许在后台定位
////    [self.locationManager setAllowsBackgroundLocationUpdates:YES];
//
//    //设置允许连续定位逆地理
//    [self.locationManager setLocatingWithReGeocode:YES];
//    [self.locationManager startUpdatingLocation];
//}

- (void)configLocationManager {
    self.locationManager = [[CLLocationManager alloc] init];
    // 设置定位距离过滤参数 （当上次定位和本次定位之间的距离 > 此值时，才会调用代理通知开发者）
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    // 设置定位精度 （精确度越高，越耗电，所以需要我们根据实际情况，设定对应的精度）
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//    self.locationManager.allowsBackgroundLocationUpdates = YES;
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
}

/**
 *用户方向更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation {}

/**
 *用户位置更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation {
    // 纬度、经度
    NSLog(@"didUpdateUserLocation lat %f,long %f\n",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
    //地理反编码
    BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc] init];
    reverseGeocodeSearchOption.reverseGeoPoint = userLocation.location.coordinate;
    BOOL flag = [_geocodesearch reverseGeoCode:reverseGeocodeSearchOption];
    if(flag) {
        NSLog(@"反geo检索发送成功");
        [_locService stopUserLocationService]; // 关闭定位服务
        
        self.longitude = [NSString stringWithFormat:@"%.6f",userLocation.location.coordinate.longitude]; // 经度
        self.latitude  = [NSString stringWithFormat:@"%.6f",userLocation.location.coordinate.latitude];  // 纬度
        
//        self.longitude = [NSNumber numberWithFloat:userLocation.location.coordinate.longitude]; // 经度
//        self.latitude  = [NSNumber numberWithFloat:userLocation.location.coordinate.latitude];  // 纬度
        
        NSDictionary *setLngLat = @{@"longitude":self.longitude,
                                    @"latitude":self.latitude};
        
        NSLog(@"setLngLat = %@",setLngLat);
        [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"setLngLat" data:setLngLat responseCallback:^(id responseData) {
            NSLog(@"定位回调：%@",responseData);
        }];
    }else{
        // 当弱网或者无网情况下，会出现授权失败，所以重启引擎
        BMKMapManager *mapManager = [[BMKMapManager alloc] init];
        [mapManager start:BAIDU_MAP_APP_KEY generalDelegate:nil];
        NSLog(@"反geo检索发送失败");
    }
}

/**
 *在地图View停止定位后，会调用此函数
 */
- (void)didStopLocatingUser {
    NSLog(@"stop locate");
}

/**
 *定位失败后，会调用此函数
 *@param error 错误号，参考CLError.h中定义的错误号
 */
- (void)didFailToLocateUserWithError:(NSError *)error {
    NSLog(@"定位失败");
    NSDictionary *setLngLat = @{@"longitude":@(locationFail),
                                @"latitude" :@(locationFail)};
    
    [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"setLngLat" data:setLngLat responseCallback:^(id responseData) {
        NSLog(@"定位失败回调：%@",responseData);
    }];
}

#pragma mark -------------地理反编码的delegate---------------
- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error {
    NSLog(@"address:%@----%@",result.addressDetail.city,result.address);
    //addressDetail:   层次化地址信息
    //address:         地址名称
    //businessCircle:  商圈名称
    //location:        地址坐标
    //poiList:         地址周边POI信息，成员类型为BMKPoiInfo
}

//////////////////////////////
#warning 高德地图
//- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error
//{
//    NSLog(@"定位失败");
//    NSDictionary *setLngLat = @{@"longitude":@(locationFail),
//                                @"latitude" :@(locationFail)};
//
//    [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"setLngLat" data:setLngLat responseCallback:^(id responseData) {
//        NSLog(@"定位失败回调：%@",responseData);
//    }];
//}
//
//- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode {
//    if (reGeocode) {
//
//        NSLog(@"reGeocodereGeocodereGeocode = %@",reGeocode.formattedAddress);
//
//        [self.locationManager stopUpdatingLocation]; // 关闭定位服务
//
//        self.longitude = [NSString stringWithFormat:@"%f",location.coordinate.longitude]; // 经度
//        self.latitude  = [NSString stringWithFormat:@"%f",location.coordinate.latitude];  // 纬度
//
//        NSDictionary *setLngLat = @{@"longitude":self.longitude,
//                                    @"latitude":self.latitude};
//
//
////        latitude = "23.357176";
////        longitude = "116.701278";
//
//        NSLog(@"setLngLat = %@",setLngLat);
//        [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"setLngLat" data:setLngLat responseCallback:^(id responseData) {
//            NSLog(@"定位回调：%@",responseData);
//        }];
//
//    }else {
//
//    }
//
//}

#warning  原生定位
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    CLLocation *location = [locations firstObject];
    
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        CLPlacemark *placemark = [placemarks firstObject];
        
        if (placemark) {
            [self.locationManager stopUpdatingLocation]; // 关闭定位服务
            
            self.longitude = [NSString stringWithFormat:@"%f",location.coordinate.longitude]; // 经度
            self.latitude  = [NSString stringWithFormat:@"%f",location.coordinate.latitude];  // 纬度
            
            NSDictionary *setLngLat = @{@"longitude":self.longitude,
                                        @"latitude":self.latitude};
            
            NSLog(@"setLngLat = %@",setLngLat);
            [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"setLngLat" data:setLngLat responseCallback:^(id responseData) {
                NSLog(@"定位回调：%@",responseData);
            }];
            
            NSLog(@"address:%@----%@",placemark.locality,[NSString stringWithFormat:@"%@%@%@%@%@",placemark.administrativeArea,placemark.locality,placemark.subLocality,placemark.thoroughfare,placemark.name]);
        }else {
            
        }
        
//        NSLog(@"placemark = %@", placemark);
//
//        NSLog(@"address:%@----%@",placemark.locality,[NSString stringWithFormat:@"%@%@%@%@%@",placemark.administrativeArea,placemark.locality,placemark.subLocality,placemark.thoroughfare,placemark.name]);
        
    }];
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"定位失败");
    NSDictionary *setLngLat = @{@"longitude":@(locationFail),
                                @"latitude" :@(locationFail)};
    
    [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"setLngLat" data:setLngLat responseCallback:^(id responseData) {
        NSLog(@"定位失败回调：%@",responseData);
    }];
}

#pragma mark - UIWebView Delegate Methods
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *hostname = request.URL.absoluteString.lowercaseString;
    NSString *urlString = [hostname stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (![hostname isEqualToString:@"about:blank"]) {
        self.hostName = urlString;
    }
//    self.hostName = urlString;
    // 调起微信支付时，将先前网页地址设置成app的标识，即不会跳回浏览器中
    if ([urlString containsString:@"wx.tenpay.com"])
    {// 判断是否有mweb_url微信支付跳转链接
        NSDictionary *headers = [request allHTTPHeaderFields];
        NSLog(@"headers = %@",headers);
        NSString *referer = [headers valueForKey:@"Referer"];
        if ([referer containsString:[NSString stringWithFormat:@"%@://",URL_DOMAIN_NAME]]) {
            return YES;
        } else {
            // relaunch with a modified request
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSURL *url = [request URL];
                    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
                    //设置Referer为app的标识(即来路地址)
                    [request setHTTPMethod:@"GET"];
                    [request setValue:[NSString stringWithFormat:@"%@://",URL_DOMAIN_NAME] forHTTPHeaderField:@"Referer"];
                    [(UIWebView*)(self.webView) loadRequest:request];
                });
            });
            return NO;
        }
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {}

// 失败
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    Utility *utility = [[Utility alloc] init];
    [utility catchError:error webView:webView];
}

// 结束
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (_timer == nil && !self.isFirstLoad) {
        [self removeBgimageView]; // 移除背景图
    }
    
    if (self.isCheckVersion) {
        [self removeBgimageView]; // 移除背景图
        self.isCheckVersion = NO;
    }
    
    if ([webView.URL.scheme containsString:@"file"])
    {//当在弱网或者无网时，需重新检查版本
        self.isCheckVersion = YES;
    }
    
    if (!self.isFirstLoad) {
        self.isFirstLoad = YES;   // 首次加载
    }
    
    [self setWebViewReturnView:webView]; // 设置webview是否显示返回按钮视图
}

#pragma mark - WKWebView Delegate Methods
- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSString *hostname = navigationAction.request.URL.absoluteString;
    if (![hostname isEqualToString:@"about:blank"]) {
        self.hostName = hostname;
    }
    NSLog(@"urlString = %@",hostname);
    
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated
        && [hostname containsString:@"tel:"]) {
        // 对于跨域，需要手动跳转
        NSString *str = navigationAction.request.URL.absoluteString;
        NSString *telStr = [str substringFromIndex:4];
        NSLog(@"telStr = %@",telStr);
        [ACETelPrompt callPhoneNumber:telStr call:nil cancel:nil];
        // 不允许web内跳转
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }else {
        NSString *urlString = [hostname stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        // 调起微信支付时，将先前网页地址设置成app的标识，即不会跳回浏览器中
        if ([urlString containsString:@"wx.tenpay.com"])
        {// 判断是否有mweb_url微信支付跳转链接
            NSDictionary *headers = [navigationAction.request allHTTPHeaderFields];
            NSLog(@"headers = %@",headers);
            NSString *referer = [headers valueForKey:@"Referer"];
            if ([referer containsString:[NSString stringWithFormat:@"%@://",URL_DOMAIN_NAME]]) {
            } else {
                // relaunch with a modified request
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSURL *url = [navigationAction.request URL];
                        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
                        //设置Referer为app的标识(即来路地址)
                        [request setHTTPMethod:@"GET"];
                        [request setValue:[NSString stringWithFormat:@"%@://",URL_DOMAIN_NAME] forHTTPHeaderField:@"Referer"];
                        [(WKWebView*)(self.webView) loadRequest:request];
                    });
                });
            }
        }

        if (![urlString hasPrefix:@"http"]) { // 不包含http或https协议，为其他协议
            NSLog(@"urlStringsd = %@",urlString);
            
            NSDictionary *bundleDic = [[NSBundle mainBundle] infoDictionary];
            NSArray *schemes = [bundleDic objectForKey:@"LSApplicationQueriesSchemes"];
            
            NSString *scheme = navigationAction.request.URL.scheme; // 获取当前链接协议
            if ([schemes containsObject:scheme])
            {// 判断当前链接协议是否在设置的白名单中
                [self openUrl:navigationAction.request.URL showOpenFailTip:YES];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
        else if([urlString containsString:@"itunes.apple.com"]) { // 跳转到App Store
            [self openUrl:navigationAction.request.URL showOpenFailTip:NO];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge completionHandler:(nonnull void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,card);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"didFinishNavigation");
    if (self.timer == nil && !self.isFirstLoad) {
        [self removeBgimageView]; // 移除背景图
    }

    if (self.isCheckVersion) {
        [self removeBgimageView]; // 移除背景图
        self.isCheckVersion = NO;
    }
    
    if ([webView.URL.scheme containsString:@"file"])
    {//当在弱网或者无网时，需重新检查版本
        self.isCheckVersion = YES;
    }
    
    if (!self.isFirstLoad) {
        self.isFirstLoad = YES;   // 首次加载
    }
    
    [self setWebViewReturnView:webView]; // 设置webview是否显示返回按钮视图
}

//开始加载数据时失败
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"didFailProvisionalNavigation");
    Utility *utility = [[Utility alloc] init];
    [utility catchError:error webView:webView];
}

//当main frame最后下载数据失败时，会回调
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    Utility *utility = [[Utility alloc] init];
    [utility catchError:error webView:webView];
}

// 处理当内存过大时，webview进程被终止，导致内容加载不出，而出现白屏情况
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    NSLog(@"进程被终止");
}

#pragma mark - 设置webview是否显示顶部返回视图（用于某些页面无法返回）
- (void)setWebViewReturnView:(id)webView {
    NSString *scheme = [NSURL URLWithString:self.hostName].scheme;
    NSLog(@"self.hostNameself.hostName = %@",self.hostName);
    if ([self.hostName containsString:@"tscenter.alipay.com"] ||
        [self.hostName containsString:@"mclient.alipay.com"]  ||
//        [self.hostName containsString:@"about:blank"] ||
        [scheme containsString:@"alipay"]) {
            self.topView.hidden = NO;
            self.isDispalyTopView = YES;
            self.webView.frame = CGRectMake(0, TopBarSafeHeight+self.topView.frame.size.height, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height-TopBarSafeHeight-BottomSafeHeight-self.topView.frame.size.height);
        }else {
            self.topView.hidden = YES;
            if (self.isDispalyTopView) {
                self.webView.frame = CGRectMake(0, TopBarSafeHeight, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height-TopBarSafeHeight-BottomSafeHeight);
                self.isDispalyTopView = NO;
            }
        }
    
#pragma mark - 暂时用于医药公司app
    if ([self.hostName containsString:@"tscenter.alipay.com"] || [self.hostName containsString:@"mclient.alipay.com"])
    {// 为支付宝页面时
        self.isReloadCart = YES; // 设置刷新采购车
    }
    
    if ([self.hostName containsString:[NSString stringWithFormat:@"%@/order/success",URL_DOMAIN_NAME]])
    {// 为采购车页面时
        if (self.isReloadCart) {
            if ([webView isKindOfClass:[WKWebView class]]) {
                [(WKWebView *)webView reload]; // 手动刷新采购车
            }else {
                [(UIWebView *)webView reload]; // 手动刷新采购车
            }
            self.isReloadCart = NO;
        }
    }
}

#pragma mark ----Action
- (void)scannerClick {
    static QRCodeReaderViewController *reader = nil;
    static TWBaseNavigationController *nav = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        reader = [QRCodeReaderViewController new];
        reader.modalPresentationStyle = UIModalPresentationFormSheet;
        nav = [[TWBaseNavigationController alloc] initWithRootViewController:reader];
        reader.fd_prefersNavigationBarHidden = YES; //隐藏导航栏
    });
    reader.delegate = self;
    
    [reader setCompletionWithBlock:^(NSString *resultAsString) {
        NSLog(@"Completion with result: %@", resultAsString);
    }];
    
    self.reader = reader;
    
    [self presentViewController:nav animated:YES completion:^{
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
            
            UIAlertView *alert =[[UIAlertView alloc]initWithTitle:nil message:@"请在iPhone的“设置-隐私-相机”选项中，允许此APP访问你的相机" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil];
            [alert show];
            
            return;
        }
    }];
}

//分享到朋友圈
- (void)wxCircleClick:(id)data {
    if ([[data objectAtIndex:5] integerValue] == mediaImageObject) {
        [self contentCapture:data]; // 分享类型为图片，进行截屏，再分享
    }else {
     [[WXShare shareInstance] shareWithUrl:[data objectAtIndex:0] title:[data objectAtIndex:1] description:[data objectAtIndex:2] imgurl:[data objectAtIndex:3] sceneType:[[data objectAtIndex:4] integerValue] mediaType:[[data objectAtIndex:5] integerValue]];
    }
}

- (void)wxWinProgramClick:(id)data {
    [[WXShare shareInstance] shareMinProgramWithUrl:[data objectAtIndex:0] title:[data objectAtIndex:1] description:[data objectAtIndex:2] userName:[data objectAtIndex:3] pagePath:[data objectAtIndex:4] hdImageUrl:[data objectAtIndex:5]];
}

- (void)contentCapture:(id)data {// 屏幕截屏处理
    [self.webView contentCaptureCompletionHandler:^(UIImage *capturedImage) {
        NSData *imgData = UIImageJPEGRepresentation(capturedImage, 1.0);
        NSString *encodedImgStr = [imgData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        NSLog(@"imgData = %lu",(unsigned long)imgData.length);
        
        [[WXShare shareInstance] shareWithUrl:encodedImgStr title:[data objectAtIndex:1] description:[data objectAtIndex:2] imgurl:[data objectAtIndex:3] sceneType:[[data objectAtIndex:4] integerValue] mediaType:[[data objectAtIndex:5] integerValue]];
        
        // 调用前端接口，恢复webView顶部导航栏
        [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"wxsharedcode" data:@"" responseCallback:^(id responseData){}];
    }];
}

- (void)gotoMeasurePage:(id)data {
    UIViewController *vc;
    _isSaved = [NSString stringWithFormat:@"%@",data];
    if ([_isSaved isEqualToString:@"1"]) {
        vc = [MeasurePageVC new];
    }else{
        vc = [SlowDiseaseMemberVC new];
    }
    [Utility gotoNextVC:vc fromViewController:self];
}

- (void)gotoSearchVC:(id)data {
    [Utility gotoNextVC:[SearchVC new] fromViewController:self];
}

//退出登录
- (void)loginOutAction {
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies])
    {
        [storage deleteCookie:cookie];
    }
    //退出登录
    [self.webView loadRequestWithString:URL_LOGINOUT];
}

// 隐藏跳过按钮
- (void)hiddenSkipBtn {
    [self.timer invalidate];
    self.timer = nil;
    
    self.countdownBtn.hidden = YES;
    
    if (self.isFirstLoad)
    {// 加载结束
        [self removeBgimageView];
    }
}

// 移除背景图
- (void)removeBgimageView {
    [self.timeout invalidate];
    self.timeout = nil;
    [self loadFinishAnimation]; // 加载结束动画以及检测版本更新
}

// 加载结束动画以及检测版本更新
- (void)loadFinishAnimation {
    // 蒙版做动画操作
    [UIView animateWithDuration:1.0 animations:^{
        self.bgImgView.alpha = 0;
    } completion:^(BOOL finished){
        [self.bgImgView removeFromSuperview];
    }];
    
    
#ifdef WaiCe
    // 只有在正式情况下才提示更新
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self hsUpdateApp]; // 检测app版本更新
    });
#endif
    
}

#pragma mark - 分享、登录的回调
- (void)onResp {
    // 微信登录
    [WXAuthor shareInstance].authorRespBlock = ^(enum WXErrCode errCode) {
        switch (errCode) {
            case WXSuccess: {//成功
                NSDictionary *userInfoDic = [[NSUserDefaults standardUserDefaults] objectForKey:WX_USER_INFO];
                NSLog(@"userInfoDic = %@",userInfoDic);
                
                [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"setOpenid" data:userInfoDic responseCallback:^(id responseData) {}];
                NSLog(@"微信登录-授权登录成功");
            }
                break;
            case WXErrCodeUserCancel: {//用户取消
                NSLog(@"微信登录-用户取消登录");
            }
                break;
            case WXErrCodeSentFail: {
                NSLog(@"微信登录-发送失败");
            }
                break;
            case WXErrCodeAuthDeny: {//授权失败
                NSLog(@"微信登录-授权失败");
            }
                break;
            default: {//微信不支持
                NSLog(@"微信登录-微信不支持");
            }
                break;
        }
    };
    
    // 微信支付
    [WXAuthor shareInstance].payRespBlock = ^(enum WXErrCode errCode) {
        switch (errCode) {
            case WXSuccess: {//支付成功
                NSLog(@"微信支付-支付成功");
                [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"jumpurl" data:@(WXSuccess) responseCallback:^(id responseData) { NSLog(@"调用完JS后的回调：%@",responseData); }];
            }
                break;
            case WXErrCodeUserCancel: {//用户取消支付
                NSLog(@"微信支付-用户取消支付");
                [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"jumpurl" data:@(WXErrCodeUserCancel) responseCallback:^(id responseData) {}];
            }
                break;
            default: {//支付失败
                NSLog(@"微信支付-微信支付失败");
                [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"jumpurl" data:@(WXErrCodeSentFail) responseCallback:^(id responseData) {}];
            }
                break;
        }
    };
}

#pragma mark - QRCodeReaderDelegate
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result {
    [self QRCodeResult:result];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)reader:(QRCodeReaderViewController *)reader didImgPickerResult:(NSString *)result {
    [self QRCodeResult:result];
}

#pragma mark - 二维码/条形码识别结果
- (void)QRCodeResult:(NSString *)result {
    if ([result isUrlString]) {// 为链接网址
        if ([result containsString:URL_DOMAIN_NAME]) {// 同一域名下直接跳转
            [self dismissViewControllerAnimated:YES completion:^{
                [self.webView loadRequestWithString:result];
            }];
            
        }else {// 不同域名做另外处理
            LinkSkipViewController *lsvc = [[LinkSkipViewController alloc] init];
            [self.reader.navigationController pushViewController:lsvc animated:YES];
            lsvc.result = result;
        }
    }else {
        [self dismissViewControllerAnimated:YES completion:^{
            NSString *urlStr = [NSString stringWithFormat:@"%@/xcode/decode?code=%@",WEB_URL,result];
            [self.webView loadRequestWithString:urlStr];
        }];
    }
}

#pragma mark - 获取通讯录
// 1. 获取权限
- (void)getAuthor {
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusNotDetermined) {
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError*  _Nullable error) {
            if (error) {
                NSLog(@"授权失败");
                [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"setContact" data:@(-1) responseCallback:^(id responseData){}];
            }else {
                NSLog(@"成功授权");
                [self openContact];
            }
        }];
    }
    else if(status == CNAuthorizationStatusRestricted) {
        NSLog(@"用户拒绝");
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusDenied) {
        NSLog(@"用户拒绝");
        [self showAlertViewAboutNotAuthorAccessContact];
    }
    else if (status == CNAuthorizationStatusAuthorized)//已经授权
    {//有通讯录权限-- 进行下一步操作
        [self openContact];
    }
}

// 2. 有通讯录权限 -- 进行下一步操作
- (void)openContact {
    // 获取指定的字段,并不是要获取所有字段，需要指定具体的字段
    NSArray *keysToFetch = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
    CNContactStore *contactStore = [[CNContactStore alloc] init];

    NSMutableArray *mutableArr = [NSMutableArray array];

    [contactStore enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        //拼接姓名
        NSString *nameStr = [NSString stringWithFormat:@"%@%@",contact.familyName,contact.givenName];

        NSArray *phoneNumbers = contact.phoneNumbers;

        NSMutableArray *phoneNumArray = [NSMutableArray array];

        for (CNLabeledValue *labelValue in phoneNumbers) {
            //遍历一个人名下的多个电话号码
            CNPhoneNumber *phonesNumber = labelValue.value;

            NSString *string = phonesNumber.stringValue;

            //去掉电话中的特殊字符
            string = [string stringByReplacingOccurrencesOfString:@"+86" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@"-" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@"(" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@")" withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
            string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];

            [phoneNumArray addObject:string];

            NSLog(@"姓名=%@, 电话号码是=%@", nameStr, string);
        }

        NSDictionary *dict = @{@"name":nameStr,@"phoneNumber":phoneNumArray};
        [mutableArr addObject:dict];
    }];

    [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"setContact" data:mutableArr responseCallback:^(id responseData){}];

    NSLog(@"mutableArr = %@",mutableArr);
}

#pragma mark - 提示没有通讯录权限
- (void)showAlertViewAboutNotAuthorAccessContact {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];

    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:[infoDictionary objectForKey:@"CFBundleDisplayName"]
                                          message:@"需要访问通讯录，请您授权"
                                          preferredStyle: UIAlertControllerStyleAlert];

    // 去授权
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"去授权" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        // UIApplicationOpenSettingsURLString 适用于iOS8及以上系统
        NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [self openUrl:url showOpenFailTip:NO];
    }];
    
    [OKAction setValue:[UIColor redColor] forKey:@"_titleTextColor"]; // 设置字体颜色
    
    // 取消
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}];
    
    [alertController addAction:cancelAction];
    [alertController addAction:OKAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - 检测app版本更新
- (void)hsUpdateApp {
    __weak __typeof(&*self)weakSelf = self;
    [TWUpdateAppVersion hs_updateWithAPPID:APP_ID block:^(NSString *currentVersion, NSString *storeVersion, NSString *openUrl, BOOL isUpdate) {
        if (isUpdate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showStoreVersion:storeVersion openUrl:openUrl];
            });
        }
    }];
}

- (void)showStoreVersion:(NSString *)storeVersion openUrl:(NSString *)openUrl {
    UIAlertController *alertConteoller = [UIAlertController alertControllerWithTitle:@"发现新版本" message:[NSString stringWithFormat:@"修复细节问题，优化交互体验，马上更新体验吧！"] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionYes = [UIAlertAction actionWithTitle:@"立即更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openUrl:[NSURL URLWithString:openUrl] showOpenFailTip:NO];
    }];
    [actionYes setValue:[UIColor redColor] forKey:@"_titleTextColor"]; // 设置字体颜色
//    UIAlertAction *actionNo = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
    [alertConteoller addAction:actionYes];
//    [alercConteoller addAction:actionNo];
    [self presentViewController:alertConteoller animated:YES completion:nil];
}

#pragma mark - 打开Url
- (void)openUrl:(NSURL *)url
    showOpenFailTip:(BOOL)showOpenFailTip {
    
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {// 跳转成功
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success){}];
        }
        else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }else
    {// 跳转失败
        if (showOpenFailTip) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示"
                                                           message:@"未检测到应用，请安装后重试"
                                                          delegate:nil
                                                 cancelButtonTitle:@"确定"
                                                 otherButtonTitles:nil];
            [alert show];
        }
    }
}

@end

