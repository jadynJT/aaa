//
//  AppDelegate.m
//  ModelDemo
//
//  Created by apple on 16/9/9.
//  Copyright © 2016年 TW. All rights reserved.
//

#import "AppDelegate.h"
#import "UINavigationController+FDFullscreenPopGesture.h"
#import "TWUpdateAppVersion.h"
#import "MainVC.h"
#import "WXAuthor.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
//#import "iflyMSC/iflyMSC.h"

#define NAVI_TEST_BUNDLE_ID @"com.baidu.navitest"  //sdk自测bundle ID

//#define NAVI_TEST_APP_KEY   @"4iv6Urll7aGKZbnCgoeA1R3Mk7Grw0iO"  //亿家人自测APP KEY

@interface AppDelegate ()<WXApiDelegate,BMKGeneralDelegate>

@property (nonatomic, strong) MainVC *mvc;

@end

@implementation AppDelegate

AppDelegate *app;
BMKMapManager* _mapManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 要使用百度地图，请先启动BaiduMapManager
    _mapManager = [[BMKMapManager alloc] init];
    BOOL ret = [_mapManager start:BAIDU_MAP_APP_KEY generalDelegate:self];
    if (!ret) {
        NSLog(@"manager start failed!");
    }
    
//    [AMapServices sharedServices].apiKey = GAODE_MAP_APP_KEY;
    
    /*-----------------  微信平台share  -------------------*/
    //向微信注册
    [WXApi registerApp:WX_APPKEY];
    
    //开始监测网络状态
//    [PPNetworkHelper startMonitoringNetwork];
    
    if (!iphoneX) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    
    // 全局添加userAgent
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    UIWebView * tempWebView = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString * userAgent = [tempWebView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    NSString *newUserAgent = [userAgent stringByAppendingString:[NSString stringWithFormat:@" TWAPP:%@/ipa",version]];
    NSLog(@"newUserAgent = %@",newUserAgent);
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:newUserAgent, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self showLaunchImage:WEB_URL];
    
    //    MainVC *mvc=[[MainVC alloc]init];
    //    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:mvc];
    //    self.window.rootViewController = nav;
    
    //    [self showLaunchImage];
    
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //        //科大讯飞语音初始化
    //        //创建语音配置,appid必须要传入，仅执行一次则可
    //        NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@",@"55b19e88"];
    //
    //        //所有服务启动前，需要确保执行createUtility
    //        [IFlySpeechUtility createUtility:initString];
    //    });
    
    return YES;
}

- (void)onGetNetworkState:(int)iError
{
    if (0 == iError) {
        NSLog(@"联网成功");
    }
    else {
        NSLog(@"onGetNetworkState %d",iError);
    }
}

- (void)onGetPermissionState:(int)iError
{
    if (0 == iError) {
        NSLog(@"授权成功");
    }
    else {
        NSLog(@"onGetPermissionState %d",iError);
    }
}

- (void)showLaunchImage:(NSString *)webUrl
{
    self.mvc = [[MainVC alloc] init];
    [self.mvc configWebView:webUrl]; // 加载webview
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:self.mvc];
    self.window.rootViewController = nav;
    self.mvc.fd_prefersNavigationBarHidden = YES; //隐藏导航栏
}

//openURL:  iOS9以下调用
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if([url.scheme isEqualToString:[NSString stringWithFormat:@"%@",WX_APPKEY]]) {
        [[WXAuthor shareInstance] handleOpenURL:url];
        //        [self.mvc handleOpenURL:url];
    }
    //    com.jztw.ysspatient
    else if ([sourceApplication isEqualToString:@"com.jztw.ysspatient"])
    {// 判断是否从医随身跳入
        NSString *paramStr = [[[url query] componentsSeparatedByString:@"param="] objectAtIndex:1];
        
        if ([paramStr containsString:URL_DOMAIN_NAME])
        {// 判断是否包含老百姓药房的url
            [self.mvc configWebView:paramStr]; // 加载url地址
            return YES;
        }
    }
    return YES;
}

//app openURL: iOS9之后调用
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
    NSLog(@"options = %@",options);
    NSLog(@"url = %@",url);
    if ([url.scheme isEqualToString:[NSString stringWithFormat:@"%@",WX_APPKEY]]) {
        [[WXAuthor shareInstance] handleOpenURL:url];
        //        [self.mvc handleOpenURL:url];
    }
//    else {
//        [self.mvc gotoMeasurePage:@(0)];
//    }
    else if ([options[@"UIApplicationOpenURLOptionsSourceApplicationKey"] isEqualToString:@"com.jztw.ysspatient"])
    {// 判断是否从医随身跳入
        NSString *paramStr = [[[url query] componentsSeparatedByString:@"param="] objectAtIndex:1];

        if ([paramStr containsString:URL_DOMAIN_NAME])
        {// 判断是否包含老百姓药房的url
            [self.mvc configWebView:paramStr]; // 加载url地址
            return YES;
        }
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {// 进入活动状态
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
#ifdef WaiCe
    TWUpdateAppVersion *appVersion = [TWUpdateAppVersion shareInstance];
    
    if (appVersion.appVersionInfo.count == 0) return;
    
    BOOL isUpdate = [appVersion.appVersionInfo[@"isUpdate"] boolValue];
    NSString *storeVersion = appVersion.appVersionInfo[@"storeVersion"];
    NSString *openUrl = appVersion.appVersionInfo[@"openUrl"];
    
    if (isUpdate) {
        [self.mvc showStoreVersion:storeVersion openUrl:openUrl];
    }
#endif
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
