
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
#import "LocationManager.h"
#import "TWUpdateAppVersion.h"
#import "GradualProgressView.h"
#import "TWBaseNavigationController.h"
#import "ScanLifeLoginViewController.h"
#import "UINavigationController+FDFullscreenPopGesture.h"
#import "LinkSkipViewController.h"
#import "TopView.h"
#import <MapKit/MapKit.h>


@interface MainVC ()<UIWebViewDelegate,WKNavigationDelegate,WKUIDelegate,QRCodeReaderDelegate,WXApiDelegate,BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate,CLLocationManagerDelegate>

//@property (strong, nonatomic) QqcWebView* webView;
@property (strong, nonatomic) QqcWebViewJavascriptBridge bridge;
@property (strong, nonatomic) GradualProgressView *bgGProgressView;
@property (strong, nonatomic) NSString *isSaved;

@property (strong, nonatomic) CLGeocoder *gecoder;         // 位置反编码

@property (strong, nonatomic) BMKGeoCodeSearch *geocodesearch; // 地理编码主类，用来查询、返回结果信息
@property (strong, nonatomic) BMKLocationService *locService;

@property (strong, nonatomic) UIProgressView *progressView;
@property (assign, nonatomic) NSUInteger loadCount;
@property (strong, nonatomic) UIImageView *bgImgView;
@property (strong, nonatomic) NSString *userAgent;

@property (strong, nonatomic) UIButton *countdownBtn;    // 倒计时按钮
@property (nonatomic, strong) NSTimer *timer;            // 计时器
@property (nonatomic, assign) NSInteger count;           // 倒计时数
@property (nonatomic, assign) BOOL isFirstLoad;          // 是否第一次加载
@property (nonatomic, assign) BOOL isCheckVersion;       // 是否已经检查版本
@property (assign, nonatomic) BOOL launchIntro;          // 是否加载引导页
@property (assign, nonatomic) BOOL isDispalyTopView;
@property (assign, nonatomic) BOOL isReloadCart;

@property (strong, nonatomic) NSString *hostName;        // URL地址

@property (strong, nonatomic) ScanLifeLoginViewController *scanLifeLoginVC; // 二维码登录界面
@property (strong, nonatomic) QRCodeReaderViewController *QRCodeVC;         // 扫码控制器

@property (nonatomic, strong) QRCodeReaderViewController *reader;
@property (nonatomic, strong) TopView *topView;

@property (strong, nonatomic) NSNumber *latitude;  // 纬度
@property (strong, nonatomic) NSNumber *longitude; // 经度

@property (strong, nonatomic) NSTimer *timers;
@property (assign, nonatomic) NSInteger ttt;


@end

@implementation MainVC

- (ScanLifeLoginViewController *)scanLifeLoginVC
{
    if (!_scanLifeLoginVC) {
        self.scanLifeLoginVC = [[ScanLifeLoginViewController alloc] init];
    }
    return _scanLifeLoginVC;
}

/** 传入控制器、url、标题 */
+ (void)showWithContro:(UIViewController *)contro{
    MainVC *vc=[MainVC new];
    UIWindow *window=[[[UIApplication sharedApplication]delegate]window];
    window.rootViewController=vc;
}

- (void)dealloc{
    _bgGProgressView = nil;
    _webView = nil;
    _bridge = nil;
    _bgImgView = nil;
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UIKeyboardWillShowNotification
//                                                  object:nil];
//
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UIKeyboardWillHideNotification
//                                                  object:nil];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if ([_isSaved isEqualToString:@"0"]) {
        if ([_webView isKindOfClass:[UIWebView class]]) {
            [(UIWebView *)_webView reload];
        }else if([_webView isKindOfClass:[WKWebView class]]){
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
    
    // 进度条
    [self configProgress];
    
    // 显示蒙版
    [self configBgView];
    
    // 加载webview
    //    [self configWebView];
    
    // 标识符
//    [self configUserAgent:self.webView];
    
//    // 注册JS交互
    [self regJSApi];
    
    // 分享、登录的回调
    [self onResp];
    
    // 开始定位
    [self startLocation];
    
//    self.ttt = 0;
    
//    self.timers = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countDownTime:) userInfo:nil repeats:YES];
    // 非必要设置，实际已设置为 NSDefaultRunLoopMode 模式
//    [[NSRunLoop currentRunLoop] addTimer:self.timers forMode:NSRunLoopCommonModes];
    
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didClickKeyboard:) name:UIKeyboardWillShowNotification object:nil];
//
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didKboardDisappear:)  name:UIKeyboardWillHideNotification object:nil];
}

//- (void)countDownTime:(NSTimer*)sender {
//    self.ttt++;
//}

#pragma mark - 初始化
//- (WKWebView *)webView {
//    if (!_webView) {
//        self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height)];
//        self.webView.UIDelegate = self;
//        self.webView.navigationDelegate = self;
//    }
//    [self.view insertSubview:_webView belowSubview:_progressView];
//    return _webView;
//}

- (QqcWebView *)webView
{
    if (nil == _webView) {
        if (NSClassFromString(@"WKWebView")) {
            if (iphoneX) {
                _webView = (QqcWebView*)[[WKWebView alloc] initWithFrame:CGRectMake(0, 44, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height-44-34)];
            }else {
                _webView = (QqcWebView*)[[WKWebView alloc] initWithFrame:CGRectMake(0, 0, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height)];
            }
//             ((WKWebView *)_webView).allowsBackForwardNavigationGestures = YES; // 开启侧滑返回上一页
            if (@available(iOS 11.0, *))
            {//  防止无导航栏时顶部出现44高度的空白 (适配iPhone X)
                ((WKWebView *)_webView).scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
            [_webView wkWebViewShowKeybord]; // 弹起键盘
        }
        else {
            _webView = (QqcWebView*)[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height)];
//            ((UIWebView *)_webView).keyboardDisplayRequiresUserAction = NO;
        }
        [self.view insertSubview:_webView belowSubview:_progressView];
    }
    return _webView;
}

- (id)bridge
{
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

#pragma mark - 注册JS接口
- (void)regJSApi
{
    WVJBHandler scannerhandle = ^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"%s 扫码被触发", __FUNCTION__);
        //调用扫码方法
        [self scannerClick];
        
        //        if ([_webView isKindOfClass:[UIWebView class]]) {
        //            [(UIWebView *)_webView reload];
        //        }else if([_webView isKindOfClass:[WKWebView class]]){
        //            [(WKWebView *)_webView reload];
        //        }
    };
    
    WVJBHandler shareHandle = ^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"%s 分享被触发", __FUNCTION__);
        NSLog(@"data===%@",data);
        //调用分享方法
        [self wxCircleClick:data];
    };
    
    WVJBHandler measureHandle = ^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"%s 完善会员资料页面被触发", __FUNCTION__);
        
        NSLog(@"测量data=====  %@",data);
        //测量页面
        [self gotoMeasurePage:data];
        
    };
    
    WVJBHandler memberSearchHandle = ^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"%s 会员搜索页面被触发", __FUNCTION__);
        //会员搜索页面
        
        [self gotoSearchVC:data];
    };
    
    WVJBHandler loginOutHandle = ^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"%s 清理缓存被触发", __FUNCTION__);
        //退出登录 清理缓存
        
        [self loginOutAction];
    };
    
    //** 微信登录 **//
    WVJBHandler wxLoginhandle = ^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"%s 微信登录", __FUNCTION__);
        NSLog(@"wxLoginData===%@",data);
//        if (![[WXAuthor shareInstance] isWXAppInstalled]) {
//            [self alert:@"您未安装微信客户端"]; // 弹框提醒
//        }else {
//            [[WXAuthor shareInstance] WeChatOAuth:WX_APPKEY];
//        }
        [WXAuthor shareInstance].viewcontroller = self;
        [[WXAuthor shareInstance] WeChatOAuth:WX_APPKEY];
    };
    
    //** 微信支付 **//
    WVJBHandler wxPayhandle = ^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"%s 微信支付", __FUNCTION__);
        NSLog(@"wxLoginData===%@",data);
        if (![[WXAuthor shareInstance] isWXAppInstalled]) {
            [self alert:@"您未安装微信客户端"]; // 弹框提醒
        }else {
            [[WXAuthor shareInstance] wechatPay:data];
        }
    };
    
    if ([self.bridge isKindOfClass:[WebViewJavascriptBridge class]])
    {
        [(WebViewJavascriptBridge*)self.bridge registerHandler:@"scancode" handler:scannerhandle];
        [(WebViewJavascriptBridge*)self.bridge registerHandler:@"wxsharedcode" handler:shareHandle];
        [(WebViewJavascriptBridge*)self.bridge registerHandler:@"measureCode" handler:measureHandle];
        [(WebViewJavascriptBridge*)self.bridge registerHandler:@"memberSearchCode" handler:memberSearchHandle];
        [(WebViewJavascriptBridge*)self.bridge registerHandler:@"loginOutCode" handler:loginOutHandle];
        [(WebViewJavascriptBridge*)self.bridge registerHandler:@"wxlogincode" handler:wxLoginhandle];
        [(WebViewJavascriptBridge*)self.bridge registerHandler:@"wxPayhandle" handler:wxPayhandle];
    }else if ([self.bridge isKindOfClass:[WKWebViewJavascriptBridge class]]){
        [(WKWebViewJavascriptBridge*)self.bridge registerHandler:@"scancode" handler:scannerhandle];
        [(WKWebViewJavascriptBridge*)self.bridge registerHandler:@"wxsharedcode" handler:shareHandle];
        [(WKWebViewJavascriptBridge*)self.bridge registerHandler:@"measureCode" handler:measureHandle];
        [(WKWebViewJavascriptBridge*)self.bridge registerHandler:@"memberSearchCode" handler:memberSearchHandle];
        [(WKWebViewJavascriptBridge*)self.bridge registerHandler:@"loginOutCode" handler:loginOutHandle];
        [(WKWebViewJavascriptBridge*)self.bridge registerHandler:@"wxlogincode" handler:wxLoginhandle];
        [(WKWebViewJavascriptBridge*)self.bridge registerHandler:@"wxPayhandle" handler:wxPayhandle];
    }
}

#pragma mark -- configMethod

- (void)configWebView:(NSString *)webUrl
{
    [self.webView loadRequestWithString:webUrl];
    [_webView setScalesPageToFit:NO];
    _webView.backgroundColor=[UIColor clearColor];
    self.webView.opaque=NO;
    
    [self.view addSubview:self.topView]; // 设置顶部视图
}

#pragma mark ----清理webView缓存
- (void)removeCache
{
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }else
    {
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

#pragma mark ----配置背景图片
- (void)configBgView{
    self.bgImgView=[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height)];
    
    NSString * key = [NSString stringWithFormat:@"%dx%d", (int)Screen_width, (int)Screen_height];
    
    if (IS_SCREEN_61_INCH && [key isEqualToString:@"414x896"]) { // 为iPhoneXR
        self.bgImgView.image = [UIImage imageNamed:@"LaunchImage-1200-Portrait-1792h"];
    }else {
        self.bgImgView.image = [UIImage imageNamed:[Utility lanchImageInch:key]];
    }
    
//    if ([Utility isIPhone6Plus]) {
//        self.bgImgView.image=[UIImage imageNamed:@"LaunchImage-800-Portrait-736h@3x"];
//    }else if ([Utility isIPhone6]){
//        self.bgImgView.image=[UIImage imageNamed:@"LaunchImage-800-667h@2x"];
//    }else if ([Utility isIPhone5]){
//        self.bgImgView.image=[UIImage imageNamed:@"LaunchImage-700-568h@2x"];
//    }else{
//        self.bgImgView.image=[UIImage imageNamed:@"LaunchImage-700@2x"];
//    }
    
    self.bgImgView.userInteractionEnabled=YES;
    [self.view addSubview:self.bgImgView];
    
    [self congigBgCountDownBtn]; // 倒计时按钮
    //    [self configBgGProgress];
    self.count = 5; // 监听通知
    [self timer]; // 启动计时器
}

- (void)configProgress{
    // 进度条
    CGFloat topMargin = 0;
    if (iphoneX) topMargin = 44;
    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, topMargin, Screen_width, 0)];
    progressView.tintColor = [UIColor orangeColor];
    progressView.trackTintColor = [UIColor whiteColor];
    [self.view addSubview:progressView];
    self.progressView = progressView;
}

#pragma mark ----计时器
- (NSTimer *)timer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}

#pragma mark - 倒计时通知回调
- (void)timerAction
{
    --self.count;
    if (self.count < 1)
    {
        [self hiddenSkipBtn];
    }else
    {
        [self.countdownBtn setTitle:[NSString stringWithFormat:@"跳过%ld",(long)self.count] forState:0];
    }
}

// 倒计时按钮
- (void)congigBgCountDownBtn
{
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

// 进度条
- (void)configBgGProgress
{
    GradualProgressView *bgGProgressView = [[GradualProgressView alloc] initWithFrame:CGRectMake(UISCREEN_BOUNCES.size.width/4, UISCREEN_BOUNCES.size.height/[HRIGHT_PROGRESS floatValue], UISCREEN_BOUNCES.size.width/2.0, 1.0)];
    bgGProgressView.layer.masksToBounds = YES;
    bgGProgressView.layer.cornerRadius = 0.5;
    
    [self.bgImgView addSubview:bgGProgressView];
    self.bgGProgressView = bgGProgressView;
    [bgGProgressView startAnimating];
    [self simulateProgress];
}

- (void)simulateProgress {
    dispatch_after(0, dispatch_get_main_queue(), ^(void){
        
        CGFloat increment = (arc4random() % 5) / 10.0f + 0.1;
        CGFloat progress  = [_bgGProgressView progress] + increment;
        [_bgGProgressView setProgress:progress];
        if (progress < 1.0) {
            
            [self simulateProgress];
        }
    });
}

#pragma mark--webViewDelegate
// 计算webView进度条
- (void)setLoadCount:(NSUInteger)loadCount {
    _loadCount = loadCount;
    if (loadCount == 0) {
        self.progressView.hidden = YES;
        [self.progressView setProgress:0 animated:NO];
    }else {
        self.progressView.hidden = NO;
        CGFloat oldP = self.progressView.progress;
        CGFloat newP = (1.0 - oldP) / (loadCount + 1) + oldP;
        if (newP > 0.95) {
            newP = 0.95;
        }
        [self.progressView setProgress:newP animated:YES];
        
    }
}

- (void)startLocation
{
    NSLog(@"进入普通定位态");
    self.locService = [[BMKLocationService alloc] init];
    self.locService.delegate = self;
    [self.locService startUserLocationService];
    self.geocodesearch = [[BMKGeoCodeSearch alloc] init];
    self.geocodesearch.delegate = self;
}

/**
 *用户方向更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation
{
    //    NSLog(@"heading is %@",userLocation.heading);
}

#pragma mark---用户位置更新后，会调用此函数
/**
 *用户位置更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    // 纬度、经度
    NSLog(@"didUpdateUserLocation lat %f,long %f\n",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
    
    //地理反编码
    BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
    reverseGeocodeSearchOption.reverseGeoPoint = userLocation.location.coordinate;
    BOOL flag = [_geocodesearch reverseGeoCode:reverseGeocodeSearchOption];
    if(flag){
        NSLog(@"反geo检索发送成功");
        [_locService stopUserLocationService];
        
        self.longitude = [NSNumber numberWithFloat:userLocation.location.coordinate.longitude]; // 经度
        self.latitude  = [NSNumber numberWithFloat:userLocation.location.coordinate.latitude];  // 纬度
        
        NSDictionary *setLngLat = @{@"longitude":self.longitude,
                                    @"latitude":self.latitude};
        NSLog(@"setLngLat = %@",setLngLat);
        [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"setLngLat" data:setLngLat responseCallback:^(id responseData) {
            NSLog(@"定位回调：%@",responseData);
        }];
        
        //*
        //        AFSecurityPolicy *securityPolicy = [[AFSecurityPolicy alloc] init];
        //        [securityPolicy setAllowInvalidCertificates:YES];
        //
        //        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        //        [manager setSecurityPolicy:securityPolicy];
        //        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        //
        //        [manager GET:@"" parameters:@{@"lat":[NSNumber numberWithFloat:userLocation.location.coordinate.latitude],@"lng":[NSNumber numberWithFloat:userLocation.location.coordinate.longitude]}  progress:^(NSProgress * _Nonnull downloadProgress) {
        //
        //        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //
        //        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //            NSLog(@"error %@",error);
        //        }];
        
    }else{
        NSLog(@"反geo检索发送失败");
    }
}

/**
 *在地图View停止定位后，会调用此函数
 *@param mapView 地图View
 */
- (void)didStopLocatingUser
{
    NSLog(@"stop locate");
}

/**
 *定位失败后，会调用此函数
 *@param mapView 地图View
 *@param error 错误号，参考CLError.h中定义的错误号
 */
- (void)didFailToLocateUserWithError:(NSError *)error
{
    NSLog(@"location error");
    
    self.locService.delegate = self;
    self.geocodesearch.delegate = self;
}

#pragma mark -------------地理反编码的delegate---------------
- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    NSLog(@"address:%@----%@",result.addressDetail.city,result.address);
    //addressDetail:   层次化地址信息
    //address:         地址名称
    //businessCircle:  商圈名称
    //location:        地址坐标
    //poiList:         地址周边POI信息，成员类型为BMKPoiInfo
}

#pragma mark - UIWebView Delegate Methods
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *hostname = request.URL.absoluteString.lowercaseString;
    NSString *urlString = [hostname stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
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
    
    if (![urlString hasPrefix:@"http"]) { // 不包含http或https协议，为其他协议
        NSLog(@"urlStringsd = %@",urlString);
        
        NSDictionary *bundleDic = [[NSBundle mainBundle] infoDictionary];
        NSArray *schemes = [bundleDic objectForKey:@"LSApplicationQueriesSchemes"];
        
        NSString *scheme = request.URL.scheme; // 获取当前链接协议
        if ([schemes containsObject:scheme])
        {// 判断当前链接协议是否在设置的白名单中
            if ([[UIApplication sharedApplication] canOpenURL:request.URL])
            {// 跳转成功
                if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)])
                {
                    [[UIApplication sharedApplication] openURL:request.URL options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @NO} completionHandler:^(BOOL success) {}];
                }
                else
                {
                    [[UIApplication sharedApplication] openURL:request.URL];
                }
            }else
            {// 跳转失败
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示"
                                                               message:@"未检测到应用，请安装后重试"
                                                              delegate:nil
                                                     cancelButtonTitle:@"确定"
                                                     otherButtonTitles:nil];
                [alert show];
            }
            return NO;
        }
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    self.loadCount++;
}

// 失败
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    self.loadCount--;
    
    if (_timer == nil && !self.isFirstLoad) {
        [self removeBgimageView]; // 移除背景图
    }
    
    if (!self.isFirstLoad) {
        self.isFirstLoad = YES;   // 首次加载
    }
    Utility *utility = [[Utility alloc]init];
    [utility catchError:error webView:webView];
}

// 结束
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    self.loadCount--;
    self.view.backgroundColor=[UIColor whiteColor];
    
    if (_timer == nil && !self.isFirstLoad) {
        [self removeBgimageView]; // 移除背景图
    }
    
    if (!self.isFirstLoad) {
        self.isFirstLoad = YES;   // 首次加载
    }
    
    [self setWebViewReturnView:webView]; // 设置webview是否显示返回按钮视图
}

#pragma mark - WKWebView Delegate Methods
- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    NSString *hostname = navigationAction.request.URL.absoluteString;
    self.hostName = hostname;
    NSLog(@"urlString = %@",hostname);
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated
        && [hostname containsString:@"tel:"]) {
        // 对于跨域，需要手动跳转
        NSString *str = navigationAction.request.URL.absoluteString;
        NSString *telStr = [str substringFromIndex:4];
        
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
                if ([[UIApplication sharedApplication] canOpenURL:navigationAction.request.URL])
                {// 跳转成功
                    if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)])
                    {
                        [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @NO} completionHandler:^(BOOL success) {}];
                    }
                    else
                    {
                        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
                    }
                }else
                {// 跳转失败
                    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示"
                                                                   message:@"未检测到应用，请安装后重试"
                                                                  delegate:nil
                                                         cancelButtonTitle:@"确定"
                                                         otherButtonTitles:nil];
                    [alert show];
                }
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
        
        //        if ([urlString containsString:@"weixin://wap/pay?"])
        //        {// 用于调起H5的微信支付
        //
        //            if ([[UIApplication sharedApplication] canOpenURL:navigationAction.request.URL])
        //            {
        //                if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)])
        //                {
        //                    [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @NO} completionHandler:^(BOOL success) {
        //
        //                    }];
        //                }
        //                else
        //                {
        //                    [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        //                }
        //            }
        //
        //            decisionHandler(WKNavigationActionPolicyCancel);
        //            return;
        //        }
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge completionHandler:(nonnull void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        
        completionHandler(NSURLSessionAuthChallengeUseCredential,card);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    self.loadCount++;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    self.loadCount--;
    if (_timer == nil && !self.isFirstLoad) {
        [self removeBgimageView]; // 移除背景图
    }
    
    if (!self.isFirstLoad) {
        self.isFirstLoad = YES;   // 首次加载
    }
    
    [self setWebViewReturnView:webView]; // 设置webview是否显示返回按钮视图
    
    
//    [self.timers invalidate];
//    self.timers = nil;
    
//    NSLog(@"tt = %ld",(long)self.ttt);
}

//开始加载数据时失败
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    self.loadCount--;
    Utility *utility = [[Utility alloc]init];
    [utility catchError:error webView:webView];
    
    if (_timer == nil && !self.isFirstLoad) {
        [self removeBgimageView]; // 移除背景图
    }
    
    if (!self.isFirstLoad) {
        self.isFirstLoad = YES;   // 首次加载
    }
}

//当main frame最后下载数据失败时，会回调
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    self.loadCount--;
    Utility *utility = [[Utility alloc]init];
    [utility catchError:error webView:webView];
}

//当web content处理完成时，会回调
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    NSLog(@"进程阻塞");
}

//- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
//    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        completionHandler();
//    }])];
//    [self presentViewController:alertController animated:YES completion:nil];
//    
//}
//- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
//    //    DLOG(@"msg = %@ frmae = %@",message,frame);
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
//    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//        completionHandler(NO);
//    }])];
//    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        completionHandler(YES);
//    }])];
//    [self presentViewController:alertController animated:YES completion:nil];
//}
//- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
//    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
//        textField.text = defaultText;
//    }];
//    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        completionHandler(alertController.textFields[0].text?:@"");
//    }])];
//    
//    
//    [self presentViewController:alertController animated:YES completion:nil];
//}

#pragma mark--设置webview是否显示顶部返回视图（用于某些页面无法返回）
- (void)setWebViewReturnView:(id)webView {
    
    if ([self.hostName containsString:@"tscenter.alipay.com"] ||
         [self.hostName containsString:@"mclient.alipay.com"]) {
            self.topView.hidden = NO;
            self.isDispalyTopView = YES;
            NSLog(@"执行了这里");
            self.webView.frame = CGRectMake(0, TopBarSafeHeight+self.topView.frame.size.height, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height-TopBarSafeHeight-BottomSafeHeight-self.topView.frame.size.height);
            
        }else {
            self.topView.hidden = YES;
            
            if (self.isDispalyTopView) {
                self.webView.frame = CGRectMake(0, TopBarSafeHeight, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height-TopBarSafeHeight-BottomSafeHeight);
                
                self.isDispalyTopView = NO;
            }
        }
    
#pragma mark --- 暂时用于医药公司app
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

#pragma mark--scannerClick
- (void)scannerClick
{
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
- (void)wxCircleClick:(id)data{
    NSLog(@"data");
    if ([WXApi isWXAppInstalled] && [WXApi isWXAppSupportApi]){
        
        WXMediaMessage *message=[WXMediaMessage message];
        
        if ([[data objectAtIndex:2]integerValue] == 0) {
            //分享到好友
            message.title = [[NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Info" ofType:@"plist"]]objectForKey:@"CFBundleName"];
        }else if ([[data objectAtIndex:2]integerValue] == 1){
            //分享到朋友圈
            message.title = [NSString stringWithFormat:@"%@",[data objectAtIndex:1]];
        }
        message.description = [NSString stringWithFormat:@"%@",[data objectAtIndex:1]];
        
        [message setThumbImage:[UIImage imageNamed:@"AppIcon29x29"]];
        
        WXWebpageObject *webpageObject=[WXWebpageObject object];
        webpageObject.webpageUrl = [NSString stringWithFormat:@"%@",[data objectAtIndex:0]];
        message.mediaObject=webpageObject;
        
        SendMessageToWXReq *req=[[SendMessageToWXReq alloc]init];
        req.bText=NO;
        req.message=message;
        
        //分享到朋友圈
        req.scene=[[data objectAtIndex:2]intValue];
        
        [WXApi sendReq:req];
        
    }else{
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"分享失败" message:@"分享平台 [微信] 尚未安装客户端！无法进行分享！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)gotoMeasurePage:(id)data{
    
    UIViewController *vc;
    
    _isSaved = [NSString stringWithFormat:@"%@",data];
    if ([_isSaved isEqualToString:@"1"]) {
        vc = [MeasurePageVC new];
    }else{
        vc = [SlowDiseaseMemberVC new];
    }
    
    [Utility gotoNextVC:vc fromViewController:self];
}

- (void)gotoSearchVC:(id)data{
    [Utility gotoNextVC:[SearchVC new] fromViewController:self];
}


//退出登录
- (void)loginOutAction{
    NSLog(@"被调用");
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
    [_timer invalidate];
    _timer = nil;
    self.countdownBtn.hidden = YES;
    
    if (self.isFirstLoad)
    {// 加载结束
        [self loadFinishAnimation]; // 加载结束动画以及检测版本更新
    }
}

// 移除背景图
- (void)removeBgimageView {
    //    if (_timer == nil && !self.launchIntro) {
    //        [self loadFinishAnimation]; // 加载结束动画以及检测版本更新
    //    }
    
    [self loadFinishAnimation]; // 加载结束动画以及检测版本更新
}

// 加载结束动画以及检测版本更新
- (void)loadFinishAnimation
{
    // 蒙版做动画操作
    [UIView animateWithDuration:1.0 animations:^{
        self.bgImgView.alpha = 0;
    } completion:^(BOOL finished){
        [self.bgImgView removeFromSuperview];
    }];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self hsUpdateApp]; // 检测app版本更新
    });
}

#pragma mark ----分享、登录的回调
- (void)onResp
{
    // 微信分享
    //    [WXAuthor shareInstance].shareRespBlock = ^(enum WXErrCode errCode){
    //        switch (errCode) {
    //            case WXSuccess:
    //            {//成功
    //                NSLog(@"微信分享-分享成功");
    ////                [self requestSharesuccess]; //请求分享成功回调
    //            }
    //                break;
    //            case WXErrCodeUserCancel:
    //            {//用户取消
    //                NSLog(@"微信分享-用户取消分享");
    ////                [self alert:@"取消分享"]; // 弹框提醒
    //            }
    //                break;
    //            case WXErrCodeSentFail:
    //            {//发送失败
    //                NSLog(@"微信分享-发送失败");
    ////                [self alert:@"发送失败"]; // 弹框提醒
    //            }
    //                break;
    //            case WXErrCodeAuthDeny:
    //            {//授权失败
    //                NSLog(@"微信分享-授权失败");
    ////                [self alert:@"授权失败"]; // 弹框提醒
    //            }
    //                break;
    //            default:
    //            {//微信不支持
    //                NSLog(@"微信分享-微信不支持");
    ////                [self alert:@"微信不支持"]; // 弹框提醒
    //            }
    //                break;
    //        }
    //    };
    
    // 微信登录
    [WXAuthor shareInstance].authorRespBlock = ^(enum WXErrCode errCode){
        switch (errCode) {
            case WXSuccess:
            {//成功
                NSString *unionID = [[NSUserDefaults standardUserDefaults]objectForKey:WX_UNION_ID];
                NSLog(@"unionID = %@",unionID);
                [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"setOpenid" data:unionID responseCallback:^(id responseData) {
                    //                    [self alert:responseData];
                    NSLog(@"调用完JS后的回调：%@",responseData);
                }];
                
                NSLog(@"微信登录-授权登录成功");
            }
                break;
            case WXErrCodeUserCancel:
            {//用户取消
                
                NSLog(@"微信登录-用户取消登录");
            }
                break;
            case WXErrCodeSentFail:
            {
                NSLog(@"微信登录-发送失败");
            }
                break;
            case WXErrCodeAuthDeny:
            {//授权失败
                NSLog(@"微信登录-授权失败");
            }
                break;
            default:
            {//微信不支持
                NSLog(@"微信登录-微信不支持");
            }
                break;
        }
    };
    
    // 微信支付
    [WXAuthor shareInstance].payRespBlock = ^(enum WXErrCode errCode){
        switch (errCode) {
            case WXSuccess:
            {//支付成功
                NSLog(@"微信支付-支付成功");
                [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"jumpurl" data:@(WXSuccess) responseCallback:^(id responseData) {
                    NSLog(@"调用完JS后的回调：%@",responseData);
                }];
            }
                break;
            case WXErrCodeUserCancel:
            {//用户取消支付
                NSLog(@"微信支付-用户取消支付");
                [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"jumpurl" data:@(WXErrCodeUserCancel) responseCallback:^(id responseData) {
                    NSLog(@"调用完JS后的回调：%@",responseData);
                }];
            }
                break;
            default:
            {//支付失败
                NSLog(@"微信支付-微信支付失败");
                [(WKWebViewJavascriptBridge*)self.bridge callHandler:@"jumpurl" data:@(WXErrCodeSentFail) responseCallback:^(id responseData) {
                    NSLog(@"调用完JS后的回调：%@",responseData);
                }];
            }
                break;
        }
    };
    
}

#pragma mark - QRCodeReaderDelegate
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result{
    [self QRCodeResult:result];
    
    //    [self dismissViewControllerAnimated:YES completion:^{
    //        if ([result isUrlString]) {// 为链接网址
    //            [self.webView loadRequestWithString:result];
    //        }else {
    //            NSString *urlStr = [NSString stringWithFormat:@"%@/xcode/decode?code=%@",WEB_URL,result];
    //            [self.webView loadRequestWithString:urlStr];
    //        }
    //    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)reader:(QRCodeReaderViewController *)reader didImgPickerResult:(NSString *)result{
    [self QRCodeResult:result];
}

#pragma mark ----二维码/条形码识别结果
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

#pragma mark ----检测app版本更新
- (void)hsUpdateApp
{
    __weak __typeof(&*self)weakSelf = self;
    [TWUpdateAppVersion hs_updateWithAPPID:APP_ID block:^(NSString *currentVersion, NSString *storeVersion, NSString *openUrl, BOOL isUpdate) {
        if (isUpdate == YES) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showStoreVersion:storeVersion openUrl:openUrl];
            });
        }
    }];
}

- (void)showStoreVersion:(NSString *)storeVersion openUrl:(NSString *)openUrl
{
    UIAlertController *alercConteoller = [UIAlertController alertControllerWithTitle:@"版本有更新" message:[NSString stringWithFormat:@"检测到新版本(%@),是否更新?",storeVersion] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionYes = [UIAlertAction actionWithTitle:@"更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:openUrl];
        [[UIApplication sharedApplication] openURL:url];
    }];
    UIAlertAction *actionNo = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alercConteoller addAction:actionYes];
    [alercConteoller addAction:actionNo];
    [self presentViewController:alercConteoller animated:YES completion:nil];
}

#pragma mark ----json解析
- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&error];
    if(error) {
        NSLog(@"json解析失败：%@",error);
        return nil;
    }
    return dic;
}

#pragma mark ----弹框提醒
- (void)alert:(NSString *)tipStr
{
    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"提示" message:tipStr delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
    
    //    UIAlertController * con = [UIAlertController alertControllerWithTitle:tipStr message:nil preferredStyle:UIAlertControllerStyleAlert];
    //    [con addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    //        //按钮触发的方法
    //    }]];
    //    [self presentViewController:con animated:YES completion:nil];
}

#pragma mark ----键盘弹起、收起方法监听
//- (void)didClickKeyboard:(NSNotification *)sender{
//    NSURL *hostUrl = [NSURL URLWithString:self.hostname];
//    NSString *query = hostUrl.query; // 参数
//    NSLog(@"query = %@",query);
//
//    if ([query containsString:@"uid"] &&
//        [self.hostname containsString:[NSString stringWithFormat:@"%@/category/searchresult",URL_DOMAIN_NAME]])
//    {// 从商品详情页返回搜索页面
//        self.hostname = @"";
//    }
//
//    if ([query containsString:@"search"] &&
//        [self.hostname containsString:[NSString stringWithFormat:@"%@/category/searchresult",URL_DOMAIN_NAME]])
//    {// 商品搜索页面
//        [self.view endEditing:YES]; // 在搜索到产品后将键盘收起
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            self.hostname = @"";
//        });
//    }
//    NSLog(@"弹起键盘");
//}
//
//- (void)didKboardDisappear:(NSNotification *)sender{
//    NSLog(@"收起键盘");
//}

@end

