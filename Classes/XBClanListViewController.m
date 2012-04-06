//
//  XBClanListViewController.m
//  Xblaze-iPhone
//
//  Created by James on 25/01/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBClanListViewController.h"
#import "XfireFriendGroup_Private.h"
#import "XfireFriendGroup.h"
#import "XfireFriendGroupController.h"
#import "Xblaze_iPhoneAppDelegate.h"
#import "MFGameRegistry.h"
#import "XfireFriend.h"
#import "XBChatController.h"
#import "XBChatViewController.h"

NSString *kClansListControllerDidAppear = @"kClansListController";

@implementation XBClanListViewController

@synthesize xfSession;
@synthesize clanID;
@synthesize clanName;

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.xfSession = nil;
	self.clanName = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(messageReceived:)
												 name:kMessageReceivedNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetUnreadCount:)
												 name:kResetUnreadCountNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateCellForTypingNote:)
												 name:kTypingNotificationRecieved
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(friendGroupDidChange:)
												 name:kXfireFriendGroupDidChangeNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(xfireFriendDidChange:)
												 name:kXfireFriendDidChangeNotification
											   object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2; // Online/Offline
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0)
	{
		return @"Online Members";
	}
	
	return @"Offline Members";
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
	{
		return [[[[[self.xfSession friendGroupController] clans] groupForID:self.clanID] onlineMembers] count];
	}
	else
	{
		return [[[[[self.xfSession friendGroupController] clans] groupForID:self.clanID] offlineMembers] count];
	}

    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"XfireFriendCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
	
	XfireFriend *friend = nil;
	XfireFriendGroup *group = [[[self.xfSession friendGroupController] clans] groupForID:self.clanID];
	
	if ([indexPath section] == 0)
	{
		friend = [[[[[self.xfSession friendGroupController] clans] groupForID:self.clanID] onlineMembers] objectAtIndex:[indexPath row]];
	}
	else if ([indexPath section] == 1)
	{
		friend = [[[[[self.xfSession friendGroupController] clans] groupForID:self.clanID] offlineMembers] objectAtIndex:[indexPath row]];
	}
	
	NSString *displayName = [friend clanNicknameForKey:[group shortName]];
	
	if ([displayName length])
		cell.textLabel.text = displayName;
	else
		cell.textLabel.text = [friend displayName];
	
	cell.detailTextLabel.text = [self statusStringForFriend:friend];
	UIImage *icon = [[MFGameRegistry registry] iconForGameID:[friend gameID]];
	cell.imageView.image = icon;
	
	if ([friend isOnline])
	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	cell.accessoryView = nil;
	XBChatController *chatController = [(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] chatControllerForFriend:friend];
	if (chatController)
	{
		if ([chatController unreadCount])
		{
			cell.accessoryView = [self unreadButtonWithLabel:[chatController unreadCount]];
		}
	}
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	XfireFriend *friend = nil;
	
	if ([indexPath section] == 0)
	{
		friend = [[[[[self.xfSession friendGroupController] clans] groupForID:self.clanID] onlineMembers] objectAtIndex:[indexPath row]];
	}
	else
	{	//don't want to be able to open chats with offline friends
		return;
	}
	
	XBChatController *chatController = [(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] chatControllerForFriend:friend];
	if (!chatController)
	{
		[self.xfSession beginChatWithFriend:friend];
		chatController = [(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] chatControllerForFriend:friend];
	}
	XBChatViewController *chatViewController = [[[XBChatViewController alloc] initWithNibName:@"XBChatViewController" bundle:nil chatController:chatController] autorelease];
	[[chatViewController navigationItem] setTitle:[friend displayName]];
	
	[self.navigationController pushViewController:chatViewController animated:YES];
}

- (UIButton *)unreadButtonWithLabel:(int)count
{
	NSString *unreadString = [NSString stringWithFormat:@"%d", count];
	CGRect unreadRect = CGRectMake(0, 0, 26, 26);
	
	if (count > 9)
	{
		unreadRect.size.width += 8;
	}
	
	if (count > 99)
	{
		unreadRect.size.width += 16;
	}
	
	UIButton *unreadButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[unreadButton setFrame:unreadRect];
	[unreadButton setBackgroundImage:[[UIImage imageNamed:@"unreadButton.png"] stretchableImageWithLeftCapWidth:12.0f topCapHeight:0.0f] forState:UIControlStateNormal];
	[unreadButton setAdjustsImageWhenHighlighted:YES];
	[unreadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[unreadButton setTitle:unreadString forState:UIControlStateNormal];
	UIEdgeInsets insets = UIEdgeInsetsMake(0.0f, 3.0f, 0.0f, 1.0f);
	[unreadButton setTitleEdgeInsets:insets];
	
	return unreadButton;
}

- (NSString *)statusStringForFriend:(XfireFriend *)friend
{
	NSString *statusString = [friend statusString];
	NSString *gameInfoString = nil;
	int gameID = [friend gameID];
	if (gameID != 0)
	{
		gameInfoString = [MFGameRegistry longNameForGameID:gameID];
	}
	
	if (![gameInfoString length])
		return statusString;
	
	if ([statusString length])
		return [NSString stringWithFormat:@"%@ - %@", gameInfoString, statusString];
	else
		return gameInfoString;
	
	return nil;
}

- (NSIndexPath *)indexPathForFriend:(XfireFriend *)friend
{
	NSIndexPath *indexPath = nil;
	
	XfireFriendGroup *group = [[[self.xfSession friendGroupController] clans] groupForID:self.clanID];
	
	if ([friend isOnline])
	{
		NSInteger row = [[group onlineMembers] indexOfObject:friend];
		if (row != NSNotFound)
			indexPath = [NSIndexPath indexPathForRow:row inSection:0];
	}
	else
	{
		NSInteger row = [[group offlineMembers] indexOfObject:friend];
		if (row != NSNotFound)
			indexPath = [NSIndexPath indexPathForRow:row inSection:1];
	}

	return indexPath;
}

- (UITableViewCell *)cellForFriend:(XfireFriend *)friend
{
	return [self.tableView cellForRowAtIndexPath:[self indexPathForFriend:friend]];	
}

- (void)friendGroupDidChange:(NSNotification *)note
{
	[self.tableView reloadData];
}

- (void)xfireFriendDidChange:(NSNotification *)note
{
	[self.tableView reloadData];
}

- (void)messageReceived:(NSNotification *)note
{
	XBChatController *chatController = (XBChatController *)[note object];
	NSIndexPath *indexPath = [self indexPathForFriend:[[chatController chat] remoteFriend]];
	if (indexPath)
	{
		[self.tableView reloadData];
	}
}

- (void)resetUnreadCount:(NSNotification *)note
{
	XBChatController *chatController = (XBChatController *)[note object];
	UITableViewCell *cell = [self cellForFriend:[[chatController chat] remoteFriend]];
	[cell setAccessoryView:nil];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
}

- (void)updateCellForTypingNote:(NSNotification *)note
{
	NSDictionary *typingDict = [note userInfo];
	XfireChat *chat = [note object];
	BOOL isTyping = [[typingDict objectForKey:@"typing"] boolValue];
	
	UITableViewCell *cell = [self cellForFriend:[chat remoteFriend]];
	
	if (isTyping)
	{
		cell.accessoryView = nil;
		UIImageView *typingIcon = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"typing.png"]] autorelease];
		cell.accessoryView = typingIcon;
	}
	else
	{
		cell.accessoryView = nil;
		
		XBChatController *chatController = [(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] chatControllerForFriend:[chat remoteFriend]];
		if (chatController)
		{
			if ([chatController unreadCount])
			{
				cell.accessoryView = [self unreadButtonWithLabel:[chatController unreadCount]];
			}
		}
	}
}

@end

