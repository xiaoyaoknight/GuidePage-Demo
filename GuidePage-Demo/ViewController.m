//
//  ViewController.m
//  GuidePage-Demo
//
//  Created by 王泽龙 on 2019/8/2.
//  Copyright © 2019 王泽龙. All rights reserved.
//

#import "ViewController.h"
#import "ZLGuidePageView.h"
#import "ZLSplashAdView.h"
#import <MSWeakTimer/MSWeakTimer.h>
#import <ZLNetWork/ZLNetWork.h>
#import "NSUserDefaults+LaunchGuide.h"

@interface ViewController ()<ZLSplashAdViewDelegate>

@property (nonatomic, strong) ZLSplashAdView *splashAdView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the viewO(∩_∩)O.
    if ([[NSUserDefaults standardUserDefaults] needShowGuide]) {
        [self setStaticGuidePage];
        [NSUserDefaults standardUserDefaults].needShowGuide = NO;
    } else {
        [self setSplashView];
    }
    
}

#pragma mark - 设置APP静态图片引导页
- (void)setStaticGuidePage {
    NSArray *imageNameArray = @[@"guideImage1.jpg",@"guideImage2.jpg",@"guideImage3.jpg",@"guideImage4.jpg",@"guideImage5.jpg"];
    ZLGuidePageView *guidePage = [[ZLGuidePageView alloc] initWithFrame:self.view.frame imageNameArray:imageNameArray hideStartButton:YES];
    guidePage.slideInto = YES;
//    guidePage.imagePageControl.frame = CGRectMake(0, 20, 100, 100);
//    guidePage.imagePageControl.pageIndicatorTintColor = [UIColor redColor];
//    guidePage.imagePageControl.currentPageIndicatorTintColor = [UIColor blueColor];
//    [guidePage.startButton setTitle:@"hehe" forState:UIControlStateNormal];
//    [guidePage.startButton setBackgroundColor:[UIColor redColor]];
//    [guidePage.skipButton setBackgroundImage:[UIImage imageNamed:@"skipButton_nor"] forState:UIControlStateNormal];
//    [guidePage.skipButton setBackgroundImage:[UIImage imageNamed:@"skipButton_press"] forState:UIControlStateHighlighted];
//    [guidePage.skipButton setTitle:@"跳过" forState:UIControlStateNormal];
//    guidePage.skipButton.frame = CGRectMake(100, 200, 50, 25);
    
    guidePage.guidePageCallBack = ^{
        if (self.callBack) {
            self.callBack();
        }
    };
    [self.view addSubview:guidePage];
}

#pragma mark - 设置APP动态图片引导页
- (void)setDynamicGuidePage {
    NSArray *imageNameArray = @[@"guideImage6.gif",@"guideImage7.gif",@"guideImage8.gif"];
    ZLGuidePageView *guidePage = [[ZLGuidePageView alloc] initWithFrame:self.view.frame imageNameArray:imageNameArray hideStartButton:YES];
    guidePage.slideInto = YES;
    guidePage.guidePageCallBack = ^{
        if (self.callBack) {
            self.callBack();
        }
    };
    [self.view addSubview:guidePage];
}

#pragma mark - 设置APP视频引导页
- (void)setVideoGuidePage {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"guideMovie1" ofType:@"mov"];
    NSURL *videoURL = [NSURL fileURLWithPath:path];
    ZLGuidePageView *guidePage = [[ZLGuidePageView alloc] initWithFrame:self.view.frame videoURL:videoURL];
    guidePage.guidePageCallBack = ^{
        if (self.callBack) {
            self.callBack();
        }
    };
    [self.view addSubview:guidePage];
}

- (void)setSplashView {
    ZLLaunchConfig *launchConfig = [[ZLLaunchConfig alloc] init];
    NSString *pic = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1565594531&di=5c72a92d5f192369c106c772f69dc77d&imgtype=jpg&er=1&src=http%3A%2F%2Fpic51.nipic.com%2Ffile%2F20141025%2F8649940_220505558734_2.jpg";
    launchConfig.pic = pic;
    launchConfig.delayTime = 5;
    launchConfig.logoImage = @"timg";
    launchConfig.links = @"http://www.baidu.com";
    
    ZLSplashAdView *splashAdView = [[ZLSplashAdView alloc] initWithFrame:self.view.frame launchConfig:launchConfig];
    splashAdView.delegate = self;
    splashAdView.finishedBlock = ^ {
        NSLog(@"结束了");
        if (self.callBack) {
            self.callBack();
        }
    };
    [self.view addSubview:splashAdView];
    
}

#pragma mark ZLSplashAdViewDelegate
- (void)didClickAdImageVieWithSplash:(ZLLaunchConfig *)launchConfig {
    // 点击闪屏图跳转
    NSLog(@"------------------%@", launchConfig.links);
}
@end
