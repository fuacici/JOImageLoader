//
//  JOAppDelegate.h
//  DemoImageLoader
//
//  Created by Joost💟Blair on 5/8/13.
//  Copyright (c) 2013 eker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JOImageLoader.h"
@interface JOAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic,strong) JOImageLoader * loader;
@property (strong, nonatomic) UIWindow *window;

@end
