//
//  XBChatRoomInviteViewController.m
//  Xblaze-iPhone
//
//  Created by James on 29/08/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBChatRoomInviteViewController.h"
#import "XfireSession.h"
#import "XfireFriend.h"
#import "XfireChatRoom.h"
#import "Xblaze_iPhoneAppDelegate.h"

@implementation XBChatRoomInviteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil chatRoom:(XfireChatRoom *)chatRoom
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		_chatRoom = [chatRoom retain];
	}
	
	return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Invite Friends";
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(sendInvites:)] autorelease];
	
	_session = [(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] xfSession];

	
	NSMutableSet *_tempFriends = [NSMutableSet set];
	NSArray *onlineFriends = [_session friendsOnline];
	NSArray *onlineClanMembers = [_session clanMembersOnline];
	[_tempFriends addObjectsFromArray:onlineFriends];
	[_tempFriends addObjectsFromArray:onlineClanMembers];
	_friends = [[[NSMutableArray arrayWithArray:[_tempFriends allObjects]] sortedArrayUsingSelector:@selector(compareFriendsByDisplayName:)] mutableCopy];
	
	for (NSInteger i = 0; i < [_friends count]; i++)
	{
		XfireFriend *friend = [_friends objectAtIndex:i];
		if ([[_chatRoom users] containsObject:friend])
			[_friends removeObject:friend];
	}
	
	_selectedFriends = [[NSMutableArray alloc] init];
	
	[onlineFriends release];
	[onlineClanMembers release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)sendInvites:(id)sender
{
	if ([_selectedFriends count])
	{
		[_session inviteUsers:_selectedFriends toChatRoom:_chatRoom];
		
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Invites Sent"
															 message:@"Friends will appear in your chat room if they accept the invitation"
															delegate:self
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] autorelease];
		[alertView show];
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else
	{
		UIViewController *chatRoomController = [[self.navigationController viewControllers] objectAtIndex:1];
		[self.navigationController popToViewController:chatRoomController animated:YES];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_friends count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	XfireFriend *friend = [_friends objectAtIndex:[indexPath row]];
	
	cell.textLabel.text = [friend displayName];
	cell.accessoryType = ([_selectedFriends containsObject:friend]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	XfireFriend *friend = [_friends objectAtIndex:[indexPath row]];
	
	if (![_selectedFriends containsObject:friend])
	{
		[_selectedFriends addObject:friend];
	}
	else
	{
		[_selectedFriends removeObject:friend];
	}
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	[_friends release], _friends = nil;
	[_selectedFriends release], _selectedFriends = nil;
	_session = nil;
}


- (void)dealloc
{
	[self viewDidUnload];
	[_chatRoom release], _chatRoom = nil;
    [super dealloc];
}


@end

