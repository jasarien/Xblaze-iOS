//
//  XBChatRoomUsersViewController.m
//  Xblaze-iPhone
//
//  Created by James on 29/08/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBChatRoomUsersViewController.h"
#import "XfireFriend.h"
#import "XfireChatRoom.h"
#import "XBChatRoomInviteViewController.h"
#import "XfireSession.h"

@implementation XBChatRoomUsersViewController

#pragma mark -
#pragma mark View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil chatRoom:(XfireChatRoom *)chatRoom
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		_chatRoom = [chatRoom retain];
		_users = [[[_chatRoom users] allObjects] mutableCopy];
	}
	
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	XFGroupChatPermissionLevel permissionLevel = [_chatRoom permissionForUser:[[_chatRoom session] loginIdentity]];
	
	if (permissionLevel >= XFGroupChatPermissionLevelPowerUser)
	{
		self.title = @"Manage Users";
		
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"19-gear.png"]
																				   style:UIBarButtonItemStyleBordered
																				  target:self
																				  action:@selector(options:)] autorelease];
	}
	else
	{
		self.title = @"Users";
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)options:(id)sender
{
	XFGroupChatPermissionLevel permissionLevel = [_chatRoom permissionForUser:[[_chatRoom session] loginIdentity]];
	
	UIActionSheet *optionsSheet = nil;
	
	if (permissionLevel >= XFGroupChatPermissionLevelModerator)
	{
		optionsSheet = [[[UIActionSheet alloc] initWithTitle:nil
												   delegate:self
										  cancelButtonTitle:@"Cancel"
									 destructiveButtonTitle:nil
										  otherButtonTitles:@"Invite Friends", @"Kick user", nil] autorelease];
		[optionsSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
	}
	else if (permissionLevel >= XFGroupChatPermissionLevelPowerUser)
	{
		optionsSheet = [[[UIActionSheet alloc] initWithTitle:nil
													delegate:self
										   cancelButtonTitle:@"Cancel"
									  destructiveButtonTitle:nil
										   otherButtonTitles:@"Invite Friends", nil] autorelease];
		[optionsSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[optionsSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
	}
	else
	{
		[optionsSheet showInView:self.view];
	}
}

- (void)inviteUser:(id)sender
{
	XBChatRoomInviteViewController *inviteViewController = [[[XBChatRoomInviteViewController alloc] initWithNibName:@"XBChatRoomInviteViewController"
																											 bundle:nil
																										   chatRoom:_chatRoom] autorelease];
	[self.navigationController pushViewController:inviteViewController animated:YES];
}

- (void)kickUser:(id)sender
{
	[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																							  target:self action:@selector(done:)] autorelease]];
	[self.tableView setEditing:YES animated:YES];
}

- (void)done:(id)sender
{
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"19-gear.png"]
																			   style:UIBarButtonItemStyleBordered
																			  target:self
																			  action:@selector(options:)] autorelease];
	[self.tableView setEditing:NO animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
	{
		[self inviteUser:self];
	}
	else if (buttonIndex != [actionSheet cancelButtonIndex])
	{
		[self kickUser:self];
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
	return [_users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.text = [[_users objectAtIndex:[indexPath row]] displayName];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return @"Kick";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	XfireFriend *loginID = [[_chatRoom session] loginIdentity];
	XfireFriend *friend = [_users objectAtIndex:[indexPath row]];
	if ([[loginID sessionID] isEqual:[friend sessionID]])
	{
		return NO;
	}
	
	return ([self.tableView isEditing]);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		XfireFriend *friend = [_users objectAtIndex:[indexPath row]];
		[_chatRoom kickUser:friend];
		
		[_users removeObjectAtIndex:[indexPath row]];
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
}


- (void)dealloc
{
	[_chatRoom release], _chatRoom = nil;
	[_users release], _users = nil;
    [super dealloc];
}


@end

