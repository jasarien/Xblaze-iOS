//
//  XBFriendRequestViewController.h
//  Xblaze-iPhone
//
//  Created by James on 20/06/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBFriendRequestTableViewCell.h"

@interface XBFriendRequestViewController : UITableViewController <XBFriendRequestTableViewCellDelegate> {

	NSMutableArray *_friendRequests;
	
}

@property (nonatomic, retain) NSMutableArray *friendRequests;

- (id)initWithStyle:(UITableViewStyle)style friendRequests:(NSMutableArray *)friendRequests;

@end
