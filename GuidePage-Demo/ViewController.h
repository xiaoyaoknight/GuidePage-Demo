//
//  ViewController.h
//  GuidePage-Demo
//
//  Created by 王泽龙 on 2019/8/2.
//  Copyright © 2019 王泽龙. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^CallBack)(void);
@interface ViewController : UIViewController

@property (nonatomic, copy) CallBack callBack;
@end

