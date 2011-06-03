//
//  SearchFriendViewController.h
//  Xblaze-iPhone
//
//  Created by James on 10/12/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Xblaze_iPhoneAppDelegate.h"

@class MBProgressHUD;

@interface XBSearchFriendViewController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource> {
	
	UISearchBar *_searchBar;
	UITableView *_resultsTable;
	
	Xblaze_iPhoneAppDelegate *app;
	
	NSArray *searchResults;
	
	MBProgressHUD *_hud;
	
	NSTimer *_timeout;
}

@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UITableView *resultsTable;
@property (nonatomic, copy)	NSArray *searchResults;

- (void)showSearchingOverlay;
- (void)hideSearchingOverlay;

- (void)searchCompleted:(NSNotification *)note;

@end
