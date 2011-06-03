//
//  XBFriendRequestViewController.m
//  Xblaze-iPhone
//
//  Created by James on 20/06/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBFriendRequestViewController.h"
#import "XfireFriend.h"
#import "XBFriendRequestTableViewCell.h"
#import "Xblaze_iPhoneAppDelegate.h"

@implementation XBFriendRequestViewController

@synthesize friendRequests = _friendRequests;

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style friendRequests:(NSMutableArray *)friendRequests
{
    if ((self = [super initWithStyle:style]))
	{
		self.friendRequests = friendRequests;
    }
    
	return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Friend Requests";
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self
																						   action:@selector(done:)] autorelease];
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)done:(id)sender
{
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ([self.friendRequests count])
	{
		return [self.friendRequests count];
	}
	
	return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.friendRequests count])
	{
		static NSString *CellIdentifier = @"FriendRequestCell";
		
		XBFriendRequestTableViewCell *cell = (XBFriendRequestTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[XBFriendRequestTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		}
		
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		[cell setFriend:[self.friendRequests objectAtIndex:[indexPath row]]];
		[cell setDelegate:self];
		
		return cell;
	}
	else
	{
		static NSString *NoInvitesCellIdentifier = @"NoFriendRequestCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NoInvitesCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NoInvitesCellIdentifier] autorelease];
		}
		
		if (indexPath.row == 1)
		{
			cell.textLabel.text = @"No Friend Invites";
			cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
			cell.textLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			
			return cell;
		}
		else
		{
			cell.textLabel.text = nil;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			return cell;
		}
	}

	return nil;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self.friendRequests count])
		return [XBFriendRequestTableViewCell heightWithText:[(XfireFriend *)[self.friendRequests objectAtIndex:[indexPath row]] statusString]];
	
	return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark -
#pragma mark XBFriendRequestTableViewCellDelegate

- (void)requestCell:(XBFriendRequestTableViewCell *)cell didAcceptInvite:(XfireFriend *)invite
{
	Xblaze_iPhoneAppDelegate *appDelegate = (Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate acceptFriendRequest:invite];
	
	NSUInteger index = [self.friendRequests indexOfObject:invite];
	
	[self.friendRequests removeObjectAtIndex:index];
	[self.tableView reloadData];
}

- (void)requestCell:(XBFriendRequestTableViewCell *)cell didDeclineInvite:(XfireFriend *)invite
{
	Xblaze_iPhoneAppDelegate *appDelegate = (Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate declineFriendRequest:invite];
	
	NSUInteger index = [self.friendRequests indexOfObject:invite];

	[self.friendRequests removeObjectAtIndex:index];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
}


- (void)dealloc
{
	self.friendRequests = nil;
    [super dealloc];
}


@end

