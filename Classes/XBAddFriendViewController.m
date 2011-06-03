//
//  XBAddFriendViewController.m
//  Xblaze-iPhone
//
//  Created by James on 11/12/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import "XBAddFriendViewController.h"


@implementation XBAddFriendViewController

@synthesize messageField = _messageField, friend = _friend, inviteLabel = _inviteLabel, tipLabel = _tipLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil xfireFriend:(XfireFriend *)friend
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		self.friend = friend;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.navigationItem setTitle:@"Send Invite"];
	app = (Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];	
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[[self.navigationController navigationBar] setBarStyle:UIBarStyleBlack];
		self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.jpg"]];
		[self.inviteLabel setFont:[UIFont boldSystemFontOfSize:24.0]];
		
		[self.tipLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
		[self.tipLabel setTextAlignment:UITextAlignmentCenter];
		CGRect tipFrame = self.tipLabel.frame;
		tipFrame.origin.y += 30;
		[self.tipLabel setFrame:tipFrame];
	}

	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
																	  style:UIBarButtonItemStyleBordered
																	 target:self
																	 action:@selector(dismiss)] autorelease];
	[self.navigationItem setLeftBarButtonItem:cancelButton];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[self.inviteLabel setText:@""];
		[self setTitle:[NSString stringWithFormat:@"Invite %@", [_friend userName]]];
	}
	else
	{
		_inviteLabel.text = [NSString stringWithFormat:@"Invite %@", [_friend userName]];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[_messageField becomeFirstResponder];
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
	self.friend = nil;
	self.messageField = nil;
	self.inviteLabel = nil;
	self.tipLabel = nil;
}

- (void)dealloc
{
	self.friend = nil;
	self.messageField = nil;
	self.inviteLabel = nil;
	self.tipLabel = nil;
	
    [super dealloc];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ([[_messageField text] length])
	{
		[[app xfSession] sendFriendInvitation:[_friend userName] message:[_messageField text]];
	}
	else
	{
		[[app xfSession] sendFriendInvitation:[_friend userName] message:[_messageField placeholder]];
	}
	
	[self dismiss];
	
	return YES;
}

- (void)dismiss
{
	[[self parentViewController] dismissModalViewControllerAnimated:YES];
}

@end
