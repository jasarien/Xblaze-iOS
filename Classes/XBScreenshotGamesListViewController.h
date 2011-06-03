//
//  XBScreenshotGamesListViewController.h
//  Xblaze-iPhone
//
//  Created by James on 21/04/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface XBScreenshotGamesListViewController : UITableViewController {

	NSDictionary *_screenshots;
	NSArray *_sortedKeys;
	
}

@property (nonatomic, retain) NSDictionary *screenshots;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil screenshots:(NSDictionary *)screenshots;

@end
