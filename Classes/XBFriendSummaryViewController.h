//
//  XBFriendSummaryViewController.h
//  Xblaze-iPhone
//
//  Created by James on 13/12/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XBFriendSummaryViewDelegate;

@interface XBFriendSummaryViewController : UIViewController {

	UILabel *_displayNameLabel;
	UILabel *_statusLabel;
	UILabel *_gameInfoLabel;
	
	UIImageView *_userImageIcon;
	UIImageView *_gameIcon;
	
	UIActivityIndicatorView *_spinner;
	
	UIButton *_profileButton;
	
	id <XBFriendSummaryViewDelegate> _delegate;
	
}

@property (nonatomic, retain) IBOutlet UILabel *displayNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UILabel *gameInfoLabel;

@property (nonatomic, retain) IBOutlet UIImageView *userImageIcon;
@property (nonatomic, retain) IBOutlet UIImageView *gameIcon;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, retain) IBOutlet UIButton *profileButton;

@property (nonatomic, assign) id <XBFriendSummaryViewDelegate> delegate;

- (IBAction)summaryViewTapped;

@end

@protocol XBFriendSummaryViewDelegate <NSObject>

- (void)friendSummaryViewTapped:(XBFriendSummaryViewController *)summaryView;

@end