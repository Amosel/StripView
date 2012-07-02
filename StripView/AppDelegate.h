//
//  AppDelegate.h
//  StripView
//
//  Created by Amos Elmaliah on 2/22/12.
//  Copyright (c) 2012 UIMUI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : NSObject <UIApplicationDelegate> {
@private
  UIWindow* _window;
  UIViewController* _rootViewController;
}

@property (nonatomic, readwrite, retain) UIWindow* window;

@end

