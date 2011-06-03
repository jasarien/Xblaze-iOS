//
//  XBFriendSummaryViewController.m
//  Xblaze-iPhone
//
//  Created by James on 13/12/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import "XBFriendSummaryViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation XBFriendSummaryViewController

@synthesize displayNameLabel = _displayNameLabel;
@synthesize statusLabel = _statusLabel;
@synthesize gameInfoLabel = _gameInfoLabel;

@synthesize userImageIcon = _userImageIcon;
@synthesize gameIcon = _gameIcon;

@synthesize spinner = _spinner;

@synthesize profileButton = _profileButton;

@synthesize delegate = _delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.userImageIcon.layer.borderWidth = 1.0f;
	self.userImageIcon.layer.borderColor = [[UIColor blackColor] CGColor];
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
	
	self.spinner = nil;
}

- (void)dealloc
{
	self.displayNameLabel = nil;
	self.statusLabel = nil;
	self.gameInfoLabel = nil;
	
	self.userImageIcon = nil;
	self.gameIcon = nil;
	
	self.spinner = nil;
	
	self.delegate = nil;
	
    [super dealloc];
}

- (IBAction)summaryViewTapped
{
	if ([_delegate respondsToSelector:@selector(friendSummaryViewTapped:)])
	{
		[_delegate friendSummaryViewTapped:self];
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesCanceled:(NSSet *)touches withEvent:(UIEvent *)event
{
}

@end
