//
//  GlucoseRecordVC.m
//  JuShanTangYaoDian
//
//  Created by apple on 17/1/6.
//  Copyright © 2017年 TW. All rights reserved.
//

#import "GlucoseRecordVC.h"

@interface GlucoseRecordVC ()<UIWebViewDelegate,WKNavigationDelegate,WKUIDelegate>

@property (nonatomic, strong)QqcWebView* webView;
@property (nonatomic, strong)QqcWebViewJavascriptBridge bridge;

@end

@implementation GlucoseRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColorFromRGBA(0xf5f5f5, 1.0);
    
    NSString *url = URL_RECORD;
    [self.webView loadRequestWithString:url];
    [self.view addSubview:_webView];
    
    [self regJSApi];
}

- (QqcWebView *)webView
{
    if (nil == _webView) {
        if (NSClassFromString(@"WKWebView"))
        {
            if (iphoneX) {
                _webView = (QqcWebView*)[[WKWebView alloc] initWithFrame:CGRectMake(0, 44, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height-44-34)];
            }else {
                _webView = (QqcWebView*)[[WKWebView alloc] initWithFrame:CGRectMake(0, 0, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height)];
            }
            if (@available(iOS 11.0, *))
            {//  防止无导航栏时顶部出现44高度的空白 (适配iPhone X)
                ((WKWebView *)_webView).scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
        }
        else
        {
            _webView = (QqcWebView*)[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, UISCREEN_BOUNCES.size.width, UISCREEN_BOUNCES.size.height)];
        }
    }
    
    return _webView;
}

- (id)bridge
{
    if (nil == _bridge) {
        
        WVJBHandler handle = ^(id data, WVJBResponseCallback responseCallback) {
            responseCallback(@"我是天网原生");
        };
        
        if ([self.webView isKindOfClass:[UIWebView class]])
        {
//            _bridge = [WebViewJavascriptBridge bridgeForWebView:(UIWebView*)self.webView webViewDelegate:self handler:handle resourceBundle:nil];
            
            _bridge = [WebViewJavascriptBridge bridgeForWebView:(UIWebView*)self.webView];
            [(WebViewJavascriptBridge *)_bridge setWebViewDelegate:self];
        }
        else if ([self.webView isKindOfClass:[WKWebView class]])
        {
//            _bridge = [WKWebViewJavascriptBridge bridgeForWebView:(WKWebView*)self.webView webViewDelegate:self handler:handle resourceBundle:nil];
            
            _bridge = [WKWebViewJavascriptBridge bridgeForWebView:(WKWebView*)self.webView];
            [(WebViewJavascriptBridge *)_bridge setWebViewDelegate:self];
        }
    }
    
    return _bridge;
}



#pragma mark - 注册JS接口
- (void)regJSApi
{
    WVJBHandler backRecordHandle = ^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"%s 数据记录页面 返回按钮 被触发", __FUNCTION__);
        
        //调用返回方法
        [self backBtnClick];
        
    };
    
    if ([self.bridge isKindOfClass:[WebViewJavascriptBridge class]])
    {
        [(WebViewJavascriptBridge*)self.bridge registerHandler:@"backCode" handler:backRecordHandle];
    }else if ([self.bridge isKindOfClass:[WKWebViewJavascriptBridge class]]){
        [(WKWebViewJavascriptBridge*)self.bridge registerHandler:@"backCode" handler:backRecordHandle];
    }}

- (void)backBtnClick{
    //返回测量页面
    self.navigationController.navigationBar.barTintColor = UIColorFromRGBA(0X38393e, 1.0);
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - UIWebView Delegate Methods
- (void)webViewDidStartLoad:(UIWebView *)webView{
    [SVProgressHUD showWithStatus:@"loading..."];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [SVProgressHUD dismiss];
    
    if (error.code == -999) {
        return;
    }
    if (error.code == -1009 || error.code == -1005) {
        [SVProgressHUD showInfoWithStatus:@"请检查您的网络状态"];
    }else if (error.code == -1001){
        [webView loadRequestWithString:URL_RECORD];
    }
}


- (void)webViewDidFinishLoad:(UIWebView *)webView{
    [SVProgressHUD dismiss];
}

#pragma mark - WKWebView Delegate Methods

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    [SVProgressHUD showWithStatus:@"loading..."];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [SVProgressHUD dismiss];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [SVProgressHUD dismiss];
    if (error.code == -999) {
        return;
    }
    
    if (error.code == -1009 || error.code == -1005) {
        [SVProgressHUD showInfoWithStatus:@"请检查您的网络状态"];
    }else if (error.code == -1001){
        [webView loadRequestWithString:URL_RECORD];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [SVProgressHUD dismiss];
    
    if (error.code == -999) {
        return;
    }
    
    if (error.code == -1009 || error.code == -1005) {
        [SVProgressHUD showInfoWithStatus:@"请检查您的网络状态"];
    }else if (error.code == -1001){
        [webView loadRequestWithString:URL_RECORD];
    }
    
    
}


@end
