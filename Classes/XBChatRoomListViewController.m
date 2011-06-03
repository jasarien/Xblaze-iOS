//
//  XBChatRoomListViewController.m
//  Xblaze-iPhone
//
//  Created by James on 16/08/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBChatRoomListViewController.h"
#import "Xblaze_iPhoneAppDelegate.h"
#import "XfireSession.h"
#import "XfireChatRoom.h"
#import "XfireFriend.h"
#import "XBChatRoomViewController.h"
#import "SoundEffect.h"

@interface XBChatRoomListViewController ()

- (void)newChatRoom:(id)sender;
- (void)handleXfireDidJoinChatRoomNotification:(NSNotification *)note;
- (void)handleXfireUpdatedChatRoomInfoNotification:(NSNotification *)note;
- (void)handleXfireFriendDidJoinChatRoomNotification:(NSNotification *)note;
- (void)handleXfireUserDidLeaveChatRoomNotification:(NSNotification *)note;
- (void)handleXfireUserKickedFromChatRoomNotification:(NSNotification *)note;
- (void)updateTabBadge;
- (UIButton *)unreadButtonWithLabel:(int)count;

@end


@implementation XBChatRoomListViewController

@synthesize chatRooms = _chatRooms;
@synthesize session = _session;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleApplicationWillResignActiveNotification:)
												 name:UIApplicationWillResignActiveNotification
											   object:nil];
	
	self.title = @"Chat Rooms";
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																							target:self
																							action:@selector(newChatRoom:)] autorelease];
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	_session = [(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] xfSession];
	
	if (!_chatRooms)
		_chatRooms = [[NSMutableArray alloc] initWithArray:[_session chatRooms]];
	
	if (!_pendingPasswordedChatRoomInvites)
		_pendingPasswordedChatRoomInvites = [[NSMutableArray alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleXfireDidJoinChatRoomNotification:)
												 name:kXfireDidJoinChatRoomNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleXfireUpdatedChatRoomInfoNotification:)
												 name:kXfireUpdatedChatRoomInfoNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleXfireFriendDidJoinChatRoomNotification:)
												 name:kXfireFriendDidJoinChatRoomNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleXfireUserDidLeaveChatRoomNotification:)
												 name:kXfireUserDidLeaveChatRoomNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleXfireUserKickedFromChatRoomNotification:)
												 name:kXfireUserKickedFromChatRoomNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleXfireJoinChatRoomPasswordRequiredNotification:)
												 name:kXfireJoinChatRoomPasswordRequiredNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleXfireJoinChatRoomInvalidPasswordNotification:)
												 name:kXfireJoinChatRoomInvalidPasswordNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleXfireChatRoomDidReceiveMessageNotification:)
												 name:kXfireChatRoomDidReceiveMessageNotification
											   object:nil];
	if (!_soundEffect)
		_soundEffect = [[SoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Blow" ofType:@"aiff"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[self.tableView reloadData];
	[self updateTabBadge];
}

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

- (void)newChatRoom:(id)sender
{
	XBPasswordInputSheet *inputSheet = [[[XBPasswordInputSheet alloc] initWithTitle:@"Create / Join Chat Room"
																		   delegate:self] autorelease];
	[inputSheet.textField setPlaceholder:@"Chat room name"];
	[inputSheet.passwordField setPlaceholder:@"Password (Optional)"];
	[inputSheet showInView:self.navigationController.view];
	
//	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Join/Create Chat Room"
//															 message:@"If the name already exists Xblaze will attempt to join that room\n\n"
//															delegate:self
//												   cancelButtonTitle:@"Cancel"
//												   otherButtonTitles:@"OK", nil] autorelease];
//	
//	UIImageView *textFieldImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"textField.png"]];
//	textFieldImage.frame = CGRectMake(11,86,262,31);
//	[alert addSubview:textFieldImage];
//	
//	UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(16,90,252,25)];
//	textField.placeholder = @"Chat room name";
//	textField.font = [UIFont systemFontOfSize:18];
//	textField.backgroundColor = [UIColor whiteColor];
//	textField.keyboardAppearance = UIKeyboardAppearanceAlert;
//	[textField becomeFirstResponder];
//	[alert addSubview:textField];
//	
//	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//		 [alert setTransform:CGAffineTransformMakeTranslation(0,109)];
//		 
//	[alert show];
//	[textField release];
//	[textFieldImage release];
//	
//	_chatNameTextField = textField; // weak reference
}

- (void)inputSheetDidDismiss:(id)inputSheet
{
	if ([inputSheet isMemberOfClass:[XBPasswordInputSheet class]])
	{
		NSString *chatRoomName = [[inputSheet textField] text];
		NSString *password = [[inputSheet passwordField] text];
		[_session createChatRoomWithName:(([chatRoomName length]) ? chatRoomName : nil) password:(([password length]) ? password : nil)];
	}
	else if ([inputSheet isMemberOfClass:[XBInputSheet class]])
	{
		[_session joinChatRoom:[_pendingPasswordedChatRoomInvites lastObject] password:[[inputSheet textField] text]];
		[_pendingPasswordedChatRoomInvites removeLastObject];
	}
}

- (void)inputSheetDidCancel:(XBInputSheet *)inputSheet
{
}

- (void)getPasswordAndJoinChatRoom:(XfireChatRoom *)chatRoom
{
	[_pendingPasswordedChatRoomInvites addObject:chatRoom];
	
	XBInputSheet *passwordSheet = [[[XBInputSheet alloc] initWithTitle:@"Enter Password"
															  delegate:self] autorelease];
	[[passwordSheet textField] setSecureTextEntry:YES];
	[[passwordSheet textField] setPlaceholder:@"Password"];
	[passwordSheet showInView:[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] window]];
}

- (void)handleXfireDidJoinChatRoomNotification:(NSNotification *)note
{
	XfireChatRoom *chatRoom = (XfireChatRoom *)[note object];
	[_chatRooms addObject:chatRoom];
	[self.tableView reloadData];
	

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:kHidePopoverNotification object:nil];
		XBChatRoomViewController *chatRoomViewController = [[[XBChatRoomViewController alloc] initWithNibName:@"XBiPadChatRoomViewController" bundle:nil session:_session chatRoom:chatRoom] autorelease];
		UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:chatRoomViewController] autorelease];
		[[navController navigationBar] setBarStyle:UIBarStyleBlack];
		[navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
		[navController setModalPresentationStyle:UIModalPresentationFullScreen];
		[[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] splitViewController] presentModalViewController:navController animated:YES];
	}
	else
	{
		NSUInteger selectedTabIndex = [self.navigationController.tabBarController selectedIndex];
		if (selectedTabIndex == 1) // chat rooms tab index
		{
			XBChatRoomViewController *chatRoomViewController = [[[XBChatRoomViewController alloc] initWithNibName:@"XBChatRoomViewController" bundle:nil session:_session chatRoom:chatRoom] autorelease];
			[self.navigationController pushViewController:chatRoomViewController animated:YES];	
		}
	}
}

- (void)handleXfireUpdatedChatRoomInfoNotification:(NSNotification *)note
{
	[self.tableView reloadData];
}

- (void)handleXfireFriendDidJoinChatRoomNotification:(NSNotification *)note
{
	[self.tableView reloadData];
}

- (void)handleXfireUserDidLeaveChatRoomNotification:(NSNotification *)note
{
	[self.tableView reloadData];
}

- (void)handleXfireJoinChatRoomPasswordRequiredNotification:(NSNotification *)note
{
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Password Required"
													 message:@"This chat room requires a password, please try again..."
													delegate:nil
										   cancelButtonTitle:@"OK"
										   otherButtonTitles:nil] autorelease];
	[alert show];
}

- (void)handleXfireJoinChatRoomInvalidPasswordNotification:(NSNotification *)note
{
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Incorrect Password"
													 message:@"The password you entered was incorrect, please try again..."
													delegate:nil
										   cancelButtonTitle:@"OK"
										   otherButtonTitles:nil] autorelease];
	[alert show];
}


- (void)handleXfireUserKickedFromChatRoomNotification:(NSNotification *)note
{
	XfireChatRoom *chatRoom = [note object];
	XfireFriend *user = [[note userInfo] objectForKey:@"user"];
	if ([user userID] == [[_session loginIdentity] userID])
	{
		[_session leaveChatRoom:chatRoom];
		NSInteger index = [_chatRooms indexOfObject:chatRoom];
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
		
		[_chatRooms removeObject:chatRoom];
		[self.tableView beginUpdates];
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self.tableView endUpdates];
		
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Kicked!"
														 message:[NSString stringWithFormat:@"You were kicked from the chat room \"%@\"", [chatRoom name]]
														delegate:nil
											   cancelButtonTitle:@"OK"
											   otherButtonTitles:nil] autorelease];
		[alert show];
	}
}

- (void)handleXfireChatRoomDidReceiveMessageNotification:(NSNotification *)note
{
	[self.tableView reloadData];
	[self updateTabBadge];
	[_soundEffect play];
}

- (void)updateTabBadge
{
	NSInteger unreadCount = 0;
	
	for (XfireChatRoom *chatRoom in _chatRooms)
	{
		unreadCount += [chatRoom unreadCount];
	}
	
	if (unreadCount > 0)
	{
		self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", unreadCount];
	}
	else
	{
		self.navigationController.tabBarItem.badgeValue = nil;
	}
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

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [_chatRooms count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	XfireChatRoom *chatRoom = [_chatRooms objectAtIndex:[indexPath row]];
	
	cell.textLabel.text = [[chatRoom name] capitalizedString];
	
	NSMutableString *detailString = [NSMutableString stringWithString:@"Users: "];
	
	for (XfireFriend *friend in [chatRoom users])
	{
		[detailString appendFormat:@"%@, ", [friend displayName]];
	}
	
	[detailString replaceCharactersInRange:NSMakeRange([detailString length] - 2, 2) withString:@""];
	cell.detailTextLabel.text = detailString;
    	
	if ([chatRoom unreadCount] > 0)
	{
		UIButton *unreadButton = [self unreadButtonWithLabel:[chatRoom unreadCount]];
		cell.accessoryView = unreadButton;
	}
	else
	{
		cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return @"Leave";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		XfireChatRoom *chatRoom = [_chatRooms objectAtIndex:[indexPath row]];
		[_session leaveChatRoom:chatRoom];
		[_chatRooms removeObject:chatRoom];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
		
		[self updateTabBadge];
    }   
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:kHidePopoverNotification object:nil];
		XfireChatRoom *chatRoom = [_chatRooms objectAtIndex:[indexPath row]];
		XBChatRoomViewController *chatRoomViewController = [[[XBChatRoomViewController alloc] initWithNibName:@"XBiPadChatRoomViewController" bundle:nil session:_session chatRoom:chatRoom] autorelease];
		UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:chatRoomViewController] autorelease];
		[[navController navigationBar] setBarStyle:UIBarStyleBlack];
		[navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
		[navController setModalPresentationStyle:UIModalPresentationFullScreen];
		[[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] splitViewController] presentModalViewController:navController animated:YES];
	}
	else
	{
		XfireChatRoom *chatRoom = [_chatRooms objectAtIndex:[indexPath row]];
		XBChatRoomViewController *chatRoomViewController = [[[XBChatRoomViewController alloc] initWithNibName:@"XBChatRoomViewController" bundle:nil session:_session chatRoom:chatRoom] autorelease];
		[self.navigationController pushViewController:chatRoomViewController animated:YES];	
	}
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
	[_soundEffect release], _soundEffect = nil;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_pendingPasswordedChatRoomInvites release], _pendingPasswordedChatRoomInvites = nil;
	[_chatRooms release], _chatRooms = nil;
	_session = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark UIAlertView / UIActionSheet Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == [alertView cancelButtonIndex])
	{
		_chatNameTextField = nil;
		return;
	}
	
	NSString *chatRoomName = nil;
	
	for (UIView *subview in [alertView subviews])
	{
		if ([subview isKindOfClass:[UITextField class]])
		{
			chatRoomName = [(UITextField *)subview text];
		}
	}
	
	_chatNameTextField = nil;

	[_session createChatRoomWithName:([chatRoomName length]) ? chatRoomName : nil];
}

#pragma mark -
#pragma mark UIApplicationNotifications

- (void)handleApplicationWillResignActiveNotification:(NSNotification *)note
{
	if (_chatNameTextField)
	{
		[_chatNameTextField resignFirstResponder];
	}
}

@end

