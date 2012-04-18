//
//  XBFriendSummaryViewController.m
//  Xblaze-iPhone
//
//  Created by James on 13/12/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import "XBFriendSummaryViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "XBLazyImageView.h"

@implementation XBFriendSummaryViewController

@synthesize displayNameLabel = _displayNameLabel;
@synthesize statusLabel = _statusLabel;
@synthesize gameInfoLabel = _gameInfoLabel;

@synthesize userImageIcon = _userImageIcon;
@synthesize gameIcon = _gameIcon;

@synthesize profileButton = _profileButton;

@synthesize delegate = _delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	UITapGestureRecognizer *tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(summaryViewTapped:)] autorelease];
	[self.view addGestureRecognizer:tapRecognizer];
	
	[self.gameIcon setShowBorder:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
	self.displayNameLabel = nil;
	self.statusLabel = nil;
	self.gameInfoLabel = nil;
	
	self.userImageIcon = nil;
	self.gameIcon = nil;
}

- (void)dealloc
{
	self.displayNameLabel = nil;
	self.statusLabel = nil;
	self.gameInfoLabel = nil;
	
	self.userImageIcon = nil;
	self.gameIcon = nil;
	
	self.delegate = nil;
	
    [super dealloc];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;
{
	[self.view setBackgroundColor:[UIColor lightGrayColor]];
	
	return YES;
}

- (IBAction)summaryViewTapped:(UITapGestureRecognizer *)recognizer
{
	[self.view setBackgroundColor:[UIColor whiteColor]];
	
	if ([recognizer state] == UIGestureRecognizerStateRecognized)
	{
		if ([_delegate respondsToSelector:@selector(friendSummaryViewTapped:)])
		{
			[_delegate friendSummaryViewTapped:self];
		}
	}
}

@end
