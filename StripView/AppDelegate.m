//
//  AppDelegate.h
//  StripView
//
//  Created by Amos Elmaliah on 2/22/12.
//  Copyright (c) 2012 UIMUI. All rights reserved.
//
//

#import "AppDelegate.h"
#import "CatalogTableViewController.h"
#import "NimbusOverview.h"


@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc {
    [_window release];
    _window = nil;
    
    NI_RELEASE_SAFELY(_rootViewController);
    
    [super dealloc];
}


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)              application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [application setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    [application setStatusBarHidden:NO];
    
    //[NIOverview applicationDidFinishLaunching];
    self.window = [[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
    
    CatalogTableViewController* catalogVC =
    [[[CatalogTableViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    
    _rootViewController = [[UINavigationController alloc] initWithRootViewController:catalogVC];
    
    [self.window addSubview:_rootViewController.view];
    
    //[NIOverview addOverviewToWindow:self.window];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}


@end
