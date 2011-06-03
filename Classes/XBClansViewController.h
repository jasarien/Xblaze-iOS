//
//  XBClansViewController.h
//  Xblaze-iPhone
//
//  Created by James on 24/01/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XfireSession.h"
#import "XBScrollableTabBar.h"

extern NSString *kClansListControllerDidAppear;

@class XBClanListViewController, XBScrollableTabBar;

@interface XBClansViewController : UIViewController <XBScrollableTabBarDelegate> {
	
	XfireSession *_xfSession;
	
	XBScrollableTabBar *_tabStrip;
	
	XBClanListViewController *_currentClanViewController;
	XBClanListViewController *_previousClanViewController;
	NSMutableArray *_clanListViewControllers;
}

@property (nonatomic, assign) XfireSession *xfSession;

- (void)removePreviousViewController;

- (void)friendGroupWasAdded:(NSNotification *)note;
- (void)friendGroupWillBeRemoved:(NSNotification *)note;
- (void)friendGroupDidChange:(NSNotification *)note;
- (void)xfSessionDidConnect;

@end
