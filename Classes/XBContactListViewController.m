//
//  XBContactListViewController.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 18/11/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import "XBContactListViewController.h"
#import "XfireFriend.h"
#import "MFGameRegistry.h"
#import "XBChatController.h"
#import "XBChatViewController.h"
#import "Xblaze_iPhoneAppDelegate.h"
#import "XBSearchFriendViewController.h"
#import "XfireFriendGroup.h"
#import "XfireFriendGroup_Private.h"
#import "XfireFriendGroupController.h"
#import "Xblaze_iPhoneAppDelegate.h"
#import "XBLoginViewController.h"
#import "XBSettingsViewController.h"
#import "XBFriendRequestViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "XBPushPurchaseViewController.h"

NSString *kContactListControllerDidAppear = @"kContactListControllerDidAppear";

#define kNicknameChangeTag 999
#define kStatusChangeTag 998

#define statusBarHeight 20.0f
#define navBarHeight	44.0f

enum {
	friendGroupOnline,
	friendGroupOffline
} friendGroupType;

@implementation XBContactListViewController

@synthesize xfSession;
@synthesize delegate = _delegate;
@synthesize searchBar;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.xfSession = nil;
	[self viewDidUnload];
	
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_appDelegate = (Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
	}

	[self.searchBar setBarStyle:UIBarStyleBlack];
		
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
											 selector:@selector(xfireFriendDidChange:)
												 name:kXfireFriendDidChangeNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(friendGroupDidChange:)
												 name:kXfireFriendGroupDidChangeNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(friendGroupWasAdded:)
												 name:kXfireFriendGroupWasAddedNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(friendGroupWillBeRemoved:)
												 name:kXfireFriendGroupWillBeRemovedNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(chatDidBegin:)
												 name:kXfireDidBeginChatNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(chatDidEnd:)
												 name:kXfireDidEndChatNotification
											   object:nil];
	
	for (UIView *searchBarSubview in [self.searchDisplayController.searchBar subviews]) {
		if ([searchBarSubview conformsToProtocol:@protocol(UITextInputTraits)]) {
			@try {
				[(UITextField *)searchBarSubview setKeyboardAppearance:UIKeyboardAppearanceAlert];
			}
			@catch (NSException * e) {
				// ignore exception
			}
		}
	}
	
	[self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];	
	
	[self.navigationItem setTitle:@"Friends"];
	
	UIBarButtonItem *addButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFriend:)] autorelease];
	[self.navigationItem setRightBarButtonItem:addButton animated:YES];
	statusNicknameButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"19-gear.png"]
															 style:UIBarButtonItemStyleBordered
															target:self
															action:@selector(chooseNicknameOrStatus:)] autorelease];
	[self.navigationItem setLeftBarButtonItem:statusNicknameButton animated:YES];
	
	XBLoginViewController *loginViewController = [_appDelegate loginViewController];
	NSString *username = [[loginViewController model] objectForKey:kUsernameKey];
	NSString *password = [loginViewController retrievePasswordForUsername:username];
	if ([username length] && [password length])
	{
		[loginViewController connect];
	}
	else
	{
		[_appDelegate showLoginView];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kContactListControllerDidAppear
														object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{	
	[super viewDidAppear:animated];
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{	
	[super viewDidUnload];
}

- (void)pushViewControllerWithAnimation:(UIViewController *)viewController
{
	[self.navigationController pushViewController:viewController animated:YES];
}

- (void)chooseNicknameOrStatus:(id)sender
{
	if (!anActionSheet)
	{
		anActionSheet = [[UIActionSheet alloc] initWithTitle:nil
												  delegate:self
										 cancelButtonTitle:nil
									destructiveButtonTitle:@"Log Off" // 0
										   otherButtonTitles:@"Show Friend Invites", @"Change Nickname", @"Change Status", @"Upgrade to Xblaze Pro", nil]; // 1, 2, 3, 4;
	
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		{
			[anActionSheet addButtonWithTitle:@"Cancel"];
			[anActionSheet setCancelButtonIndex:5];
			[anActionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
			[anActionSheet showInView:self.tabBarController.view];
		}
		else
		{
			[anActionSheet addButtonWithTitle:@"Settings"]; // 5
			[anActionSheet addButtonWithTitle:@"Cancel"]; // 6
			[anActionSheet setCancelButtonIndex:6];
			[anActionSheet showFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES];
		}
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		if (buttonIndex == 5)
		{
			XBSettingsViewController *settingsViewController = [[[XBSettingsViewController alloc] initWithNibName:@"XBSettingsViewController" bundle:nil] autorelease];
			UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:settingsViewController] autorelease];
			[[navController navigationBar] setBarStyle:UIBarStyleBlack];
			[navController setModalPresentationStyle:UIModalPresentationFormSheet];
			[navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
			[self presentModalViewController:navController animated:YES];
		}
	}
	
	if (buttonIndex == 1)
	{
		[self showInvites];
	}
	else if (buttonIndex == 2)
	{ // change nickname
		[self changeNickname];
	}
	else if (buttonIndex == 3)
	{ // Change status
		[self changeStatus];
	}
	else if (buttonIndex == 4)
	{ // upgrade
		[self upgrade];
	}
	else if (buttonIndex == [actionSheet destructiveButtonIndex])
	{ // Log off
		[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] disconnect];
	}
	
	[anActionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
	[anActionSheet release], anActionSheet = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	[anActionSheet release], anActionSheet = nil;
}

- (void)upgrade
{
	XBPushPurchaseViewController *vc = [[[XBPushPurchaseViewController alloc] initWithNibName:@"XBPushPurchaseViewController" bundle:nil] autorelease];
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
	[[navController navigationBar] setBarStyle:UIBarStyleBlack];
	[self presentModalViewController:navController animated:YES];
}

- (void)showInvites
{
	NSMutableArray *requests = [[[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] friendRequests] mutableCopy] autorelease];
	XBFriendRequestViewController *friendRequestViewController = [[[XBFriendRequestViewController alloc] initWithStyle:UITableViewStylePlain friendRequests:requests] autorelease];
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:friendRequestViewController] autorelease];
	[navController.navigationBar setBarStyle:UIBarStyleBlack];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[navController setModalPresentationStyle:UIModalPresentationFormSheet];
		[navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
	}
	
	[self presentModalViewController:navController animated:YES];
}

- (void)changeNickname
{
	XfireFriend *loginIdentity = [xfSession loginIdentity];
	
	nicknameSheet = [[[XBInputSheet alloc] initWithTitle:@"Change Nickname" delegate:self] autorelease];
	[nicknameSheet.textField setText:[loginIdentity nickName]];
	[nicknameSheet.textField setPlaceholder:[loginIdentity userName]];
	[nicknameSheet.textField setClearButtonMode:UITextFieldViewModeAlways];
	[nicknameSheet showInView:self.navigationController.view];
}

- (void)changeStatus
{
	XfireFriend *loginIdentity = [xfSession loginIdentity];
	
	statusSheet = [[[XBInputSheet alloc] initWithTitle:@"Change Status" delegate:self] autorelease];
	[statusSheet.textField setText:[loginIdentity statusString]];
	[statusSheet.textField setClearButtonMode:UITextFieldViewModeAlways];
	[statusSheet showInView:self.navigationController.view];
}

- (void)inputSheetDidDismiss:(XBInputSheet *)inputSheet
{
	if (inputSheet == nicknameSheet)
	{
		[xfSession setNickname:[nicknameSheet.textField text]];
		nicknameSheet = nil;
	}
	else if (inputSheet == statusSheet)
	{
		[xfSession setStatusString:[statusSheet.textField text]];
		statusSheet = nil;
	}
}

- (void)inputSheetDidCancel:(XBInputSheet *)inputSheet
{
	if (inputSheet == nicknameSheet)
		nicknameSheet = nil;
	else if (inputSheet == statusSheet)
		statusSheet = nil;
}

- (void)addFriend:(id)sender
{
	XBSearchFriendViewController *searchController = [[[XBSearchFriendViewController alloc] initWithNibName:@"XBSearchFriendViewController" bundle:nil] autorelease];
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:searchController] autorelease];
	[[navController navigationBar] setBarStyle:UIBarStyleBlack];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{		
		[navController setModalPresentationStyle:UIModalPresentationFormSheet];
		[navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
	}
	
	[self presentModalViewController:navController animated:YES];
}

- (void)chatDidBegin:(NSNotification *)note
{
	[self.tableView reloadData];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"autoShowNewChat"])
	{
		NSString *lastActiveChatUsername = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastActiveChatUsername"];
		if ([lastActiveChatUsername length])
		{
			XBChatController *chatController = [_appDelegate chatControllerForFriend:[xfSession friendForUserName:lastActiveChatUsername]];
			XBChatViewController *chatViewController = [[[XBChatViewController alloc] initWithNibName:@"XBChatViewController" bundle:nil chatController:chatController] autorelease];
			[chatViewController setTitle:[[[chatController chat] remoteFriend] displayName]];
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			{
				if ([self.delegate respondsToSelector:@selector(updateChatViewControllerWithChatController:)])
				{
					[self.delegate updateChatViewControllerWithChatController:chatController];	
				}
			}
			else
			{
				[self.navigationController pushViewController:chatViewController animated:YES];
			}
		}
		
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"autoShowNewChat"];
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"lastActiveChatUsername"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (void)chatDidEnd:(NSNotification *)note
{
	[self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == [alertView cancelButtonIndex])
		return;
	
	if ([alertView tag] == kNicknameChangeTag)
	{
		NSString *nickname = nil;
		
		if (buttonIndex == 1)
		{
			for (UIView *subview in [alertView subviews])
			{
				if ([subview isKindOfClass:[UITextField class]])
				{
					nickname = [(UITextField *)subview text];
				}
			}	
		}

		[xfSession setNickname:nickname];
	}
	else if ([alertView tag] == kStatusChangeTag)
	{
		NSString *status = nil;
		
		if (buttonIndex == 1)
		{
			for (UIView *subview in [alertView subviews])
			{
				if ([subview isKindOfClass:[UITextField class]])
				{
					status = [(UITextField *)subview text];
				}
			}
		}
		
		[xfSession setStatusString:status];
	}
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (tableView == self.tableView)
	{
		BOOL activeChats = NO;
		
		if ([[_appDelegate chatControllers] count])
			activeChats = YES;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			return [[[self.xfSession friendGroupController] groups] count] + ((activeChats) ? 1 : 0);
		}
		else
		{
			return [[[self.xfSession friendGroupController] groupsExcludingClans] count] + ((activeChats) ? 1 : 0);
		}
	}
	
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (tableView == self.tableView)
	{
		BOOL activeChats = NO;
		
		if ([[_appDelegate chatControllers] count])
		{
			activeChats = YES;
			if (section == 0  && tableView == self.tableView)
			{
				return @"Active Chats";
			}
		}
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			return [[[[self.xfSession friendGroupController] groups] objectAtIndex:section - ((activeChats) ? 1 : 0)] groupName];
		}
		else
		{
			return [[[[self.xfSession friendGroupController] groupsExcludingClans] objectAtIndex:section - ((activeChats) ? 1 : 0)] groupName];
		}
	}
	
	return nil;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.tableView)
	{
		BOOL activeChats = NO;
		if ([[_appDelegate chatControllers] count])
		{
			activeChats = YES;
			
			if (section == 0  && tableView == self.tableView)
			{
				return [[_appDelegate chatControllers] count];
			}
		}
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			XfireFriendGroup *group = [[[self.xfSession friendGroupController] groups] objectAtIndex:section - ((activeChats) ? 1 : 0)];
			
			if ([group groupType] == kXfireFriendGroupClan)
			{
				return [[group onlineMembers] count];
			}
			else
				return [group numberOfMembers];
		}
		else
			return [[[[self.xfSession friendGroupController] groupsExcludingClans] objectAtIndex:section - ((activeChats) ? 1 : 0)] numberOfMembers];
	}
	
	NSPredicate *predicate = nil;
	
	switch (self.searchDisplayController.searchBar.selectedScopeButtonIndex) {
		case 0: // nickname search
			predicate = [NSPredicate predicateWithFormat:@"SELF.displayName contains[cd] %@", self.searchDisplayController.searchBar.text];
			break;
		case 1: // username search
			predicate = [NSPredicate predicateWithFormat:@"SELF.userName contains[cd] %@", self.searchDisplayController.searchBar.text];
			break;
		default:
			break;
	}
	
	[_searchResults release];
	_searchResults = nil;
	_searchResults = [[[self.xfSession friends] filteredArrayUsingPredicate:predicate] retain];
	return [_searchResults count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"XfireFriendCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
	
	BOOL activeChats = NO;
	XfireFriend *friend = nil;
	
	if ([[_appDelegate chatControllers] count])
	{
		activeChats = YES;
		
		if ([indexPath section] == 0 && tableView == self.tableView)
		{
			XBChatController *chatController = [[_appDelegate chatControllers] objectAtIndex:[indexPath row]];
			friend = [[chatController chat] remoteFriend];
			
			cell.textLabel.text = [friend displayName];
			cell.detailTextLabel.text = [self statusStringForFriend:friend];
			UIImage *icon = [[MFGameRegistry registry] iconForGameID:[friend gameID]];
			cell.imageView.image = icon;
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			
			cell.accessoryView = nil;
			
			if ([chatController unreadCount])
			{
				cell.accessoryView = [self unreadButtonWithLabel:[chatController unreadCount]];
			}
			
			return cell;
		}
	}
	
	
	XfireFriendGroup *group = nil;
	
	if (tableView == self.tableView)
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			group = [[[self.xfSession friendGroupController] groups] objectAtIndex:[indexPath section] - ((activeChats) ? 1 : 0)];
			
			if ([group groupType] == kXfireFriendGroupClan)
				friend = [[group onlineMembers] objectAtIndex:[indexPath row]];
			else
				friend = [group memberAtIndex:[indexPath row]];
		}
		else
		{
			friend = [[[[self.xfSession friendGroupController] groupsExcludingClans] objectAtIndex:[indexPath section] - ((activeChats) ? 1 : 0)] memberAtIndex:[indexPath row]];
			group = [[[self.xfSession friendGroupController] groupsExcludingClans] objectAtIndex:[indexPath section] - ((activeChats) ? 1 : 0)];
		}
	}
	else
	{
		friend = [_searchResults objectAtIndex:[indexPath row]];
	}

	
	if ([group groupType] == kXfireFriendGroupClan)
	{
		NSString *displayName = [friend clanNicknameForKey:[group shortName]];
		
		if ([displayName length])
			cell.textLabel.text = [friend clanNicknameForKey:[group shortName]];
		else
			cell.textLabel.text = [friend displayName];
	}
	else
	{
		cell.textLabel.text = [friend displayName];
	}

	cell.detailTextLabel.text = [self statusStringForFriend:friend];
	UIImage *icon = [[MFGameRegistry registry] iconForGameID:[friend gameID]];
	cell.imageView.image = icon;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	cell.accessoryView = nil;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	XfireFriend *friend;
	
	BOOL activeChats = NO;
	if ([[_appDelegate chatControllers] count])
	{
		activeChats = YES;
		
		if ([indexPath section] == 0 && tableView == self.tableView)
		{
			XBChatController *chatController = [[_appDelegate chatControllers] objectAtIndex:[indexPath row]];
			XBChatViewController *chatViewController = [[[XBChatViewController alloc] initWithNibName:@"XBChatViewController" bundle:nil chatController:chatController] autorelease];
			[chatViewController setTitle:[[[chatController chat] remoteFriend] displayName]];
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			{
				if ([self.delegate respondsToSelector:@selector(updateChatViewControllerWithChatController:)])
				{
					[self.delegate updateChatViewControllerWithChatController:chatController];	
				}
			}
			else
			{
				[self.navigationController pushViewController:chatViewController animated:YES];
			}
			return;
		}
	}
		
	if (tableView == self.tableView)
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			XfireFriendGroup *group = [[[self.xfSession friendGroupController] groups] objectAtIndex:[indexPath section] - ((activeChats) ? 1 : 0)];
			if ([group groupType] == kXfireFriendGroupClan)
				friend = [[group onlineMembers] objectAtIndex:[indexPath row]];
			else
				friend = [group memberAtIndex:[indexPath row]];
		}
		else
			friend = [[[[self.xfSession friendGroupController] groupsExcludingClans] objectAtIndex:[indexPath section] - ((activeChats) ? 1 : 0)] memberAtIndex:[indexPath row]];
	}
	else
		friend = [_searchResults objectAtIndex:[indexPath row]];
	
	XBChatController *chatController = [(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] chatControllerForFriend:friend];
	if (!chatController)
	{
		[xfSession beginChatWithFriend:friend];
		chatController = [(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] chatControllerForFriend:friend];
	}
	
	[self.searchDisplayController setActive:NO animated:YES];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		if ([self.delegate respondsToSelector:@selector(updateChatViewControllerWithChatController:)])
		{
			[self.delegate updateChatViewControllerWithChatController:chatController];	
		}
	}
	else 
	{
		XBChatViewController *chatViewController = [[[XBChatViewController alloc] initWithNibName:@"XBChatViewController" bundle:nil chatController:chatController] autorelease];
		[[chatViewController navigationItem] setTitle:[friend displayName]];
		[self.navigationController pushViewController:chatViewController animated:YES];
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([[_appDelegate chatControllers] count] && [indexPath section] == 0 && tableView == self.tableView)
	{
		return @"Close chat";
	}
	
	return @"Delete";
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView != self.tableView)
		return NO;

	BOOL activeChats = NO;
	if ([[_appDelegate chatControllers] count])
	{
		activeChats = YES;
		
		if ([indexPath section] == 0  && tableView == self.tableView)
		{
			return YES;
		}
	}
	
	if ((!activeChats) && ([indexPath section] > 3)) // horrid hack to work around race condition when closing chats
		return NO;
	
	XfireFriendGroupType type;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		type = [[[[self.xfSession friendGroupController] groups] objectAtIndex:[indexPath section] - ((activeChats) ? 1 : 0)] groupType];
	else
		type = [[[[self.xfSession friendGroupController] groupsExcludingClans] objectAtIndex:[indexPath section] - ((activeChats) ? 1 : 0)] groupType];
	
	if (type == kXfireFriendGroupClan || type == kXfireFriendGroupCustom || type == kXfireFriendGroupFriendOfFriends)
		return NO;
	
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	BOOL activeChats = NO;
	if ([[_appDelegate chatControllers] count])
	{
		activeChats = YES;
		
		if ([indexPath section] == 0  && tableView == self.tableView && editingStyle == UITableViewCellEditingStyleDelete)
		{
			XBChatController *chatController = [[_appDelegate chatControllers] objectAtIndex:[indexPath row]];
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			{
				if ([[[[chatController chat] remoteFriend] userName] isEqualToString:[[[[self.delegate activeChatController] chat] remoteFriend] userName]])
				{
					if ([self.delegate respondsToSelector:@selector(updateChatViewControllerWithChatController:)])
					{
						[self.delegate updateChatViewControllerWithChatController:nil];	
					}
				}
			}
			
			[self.xfSession closeChat:[chatController chat]];
			[[NSNotificationCenter defaultCenter] postNotificationName:kContactListControllerDidAppear
																object:nil];
			return;
		}
	}
	
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		XfireFriend *friend = nil;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			friend = [[[[self.xfSession friendGroupController] groups] objectAtIndex:[indexPath section] - ((activeChats) ? 1 : 0)] memberAtIndex:[indexPath row]];
		else
			friend = [[[[self.xfSession friendGroupController] groupsExcludingClans] objectAtIndex:[indexPath section] - ((activeChats) ? 1 : 0)] memberAtIndex:[indexPath row]];
		
		[self.xfSession sendRemoveFriend:friend];
	}
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

- (void)friendGroupDidChange:(NSNotification *)note
{
	[self.tableView reloadData];
}

- (void)friendGroupWasAdded:(NSNotification *)note
{
	[self.tableView reloadData];
}

- (void)friendGroupWillBeRemoved:(NSNotification *)note
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
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[_appDelegate chatControllers] indexOfObject:chatController] inSection:0];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
	else
	{
		if ([[[chatController chat] remoteFriend] isDirectFriend])
		{
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		}
	}
}

- (void)resetUnreadCount:(NSNotification *)note
{
	XBChatController *chatController = (XBChatController *)[note object];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[_appDelegate chatControllers] indexOfObject:chatController] inSection:0];
	
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	[cell setAccessoryView:nil];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
}

- (void)updateCellForTypingNote:(NSNotification *)note
{
	NSDictionary *typingDict = [note userInfo];
	XfireChat *chat = [note object];
	BOOL isTyping = [[typingDict objectForKey:@"typing"] boolValue];
	
	XBChatController *chatController = [_appDelegate chatControllerForFriend:[chat remoteFriend]];
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[_appDelegate chatControllers] indexOfObject:chatController] inSection:0];
	
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	if (isTyping)
	{
		cell.accessoryView = nil;
		UIImageView *typingIcon = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"typing.png"]] autorelease];
		cell.accessoryView = typingIcon;
	}
	else
	{
		cell.accessoryView = nil;

		if ([chatController unreadCount])
		{
			cell.accessoryView = [self unreadButtonWithLabel:[chatController unreadCount]];
		}
	}
}

@end

