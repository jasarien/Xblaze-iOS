//
//  XBFriendSummaryViewController.h
//  Xblaze-iPhone
//
//  Created by James on 13/12/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XBLazyImageView;

@protocol XBFriendSummaryViewDelegate;

@interface XBFriendSummaryViewController : UIViewController <UIGestureRecognizerDelegate> {

	UILabel *_displayNameLabel;
	UILabel *_statusLabel;
	UILabel *_gameInfoLabel;
	
	XBLazyImageView *_userImageIcon;
	XBLazyImageView *_gameIcon;
	
	UIButton *_profileButton;
	
	id <XBFriendSummaryViewDelegate> _delegate;
	
}

@property (nonatomic, retain) IBOutlet UILabel *displayNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UILabel *gameInfoLabel;

@property (nonatomic, retain) IBOutlet XBLazyImageView *userImageIcon;
@property (nonatomic, retain) IBOutlet XBLazyImageView *gameIcon;

@property (nonatomic, retain) IBOutlet UIButton *profileButton;

@property (nonatomic, assign) id <XBFriendSummaryViewDelegate> delegate;

- (IBAction)summaryViewTapped:(id)sender;

@end

@protocol XBFriendSummaryViewDelegate <NSObject>

- (void)friendSummaryViewTapped:(XBFriendSummaryViewController *)summaryView;

@end