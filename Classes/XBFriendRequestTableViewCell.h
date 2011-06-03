//
//  XBFriendRequestTableViewCell.h
//  Xblaze-iPhone
//
//  Created by James on 20/06/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XfireFriend;
@class XBFriendRequestTableViewCell;

@protocol XBFriendRequestTableViewCellDelegate <NSObject>

- (void)requestCell:(XBFriendRequestTableViewCell *)cell didAcceptInvite:(XfireFriend *)invite;
- (void)requestCell:(XBFriendRequestTableViewCell *)cell didDeclineInvite:(XfireFriend *)invite;

@end


@interface XBFriendRequestTableViewCell : UITableViewCell {

	XfireFriend *_friend;
	
	UIButton *_declineButton;
	UIButton *_acceptButton;
	
	id <XBFriendRequestTableViewCellDelegate> _delegate;
	
}

@property (nonatomic, retain) XfireFriend *friend;
@property (nonatomic, retain) id <XBFriendRequestTableViewCellDelegate> delegate;

+ (CGFloat)heightWithText:(NSString *)text;

- (void)decline:(id)sender;
- (void)accept:(id)sender;

@end
