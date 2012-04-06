//
//  XBClansViewController.h
//  Xblaze-iPhone
//
//  Created by James on 24/01/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XfireSession.h"

@interface XBClansViewController : UITableViewController {
	
	XfireSession *_xfSession;
	
	NSMutableArray *_clanListViewControllers;
}

@property (nonatomic, assign) XfireSession *xfSession;

- (void)friendGroupWasAdded:(NSNotification *)note;
- (void)friendGroupWillBeRemoved:(NSNotification *)note;
- (void)friendGroupDidChange:(NSNotification *)note;

- (void)xfSessionDidConnect;

@end
