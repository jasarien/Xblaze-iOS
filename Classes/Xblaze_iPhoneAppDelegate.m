//
//  Xblaze_iPhoneAppDelegate.m
//  Xblaze-iPhone
//
//  Created by James on 12/11/2009.
//  Copyright JamSoft 2009. All rights reserved.
//

#import "Xblaze_iPhoneAppDelegate.h"
#import <CoreGraphics/CoreGraphics.h>
#import "XBContactListViewController.h"
#import "XBSettingsViewController.h"
#import "XBClansViewController.h"
#import "NSData_XfireAdditions.h"
#import "XBDetailViewController.h"
#import "XBChatViewController.h"
#import "XBChatRoomListViewController.h"
#import "XBChatRoomViewController.h"
#import "XfireFriend.h"
#import "XfireChatRoom.h"
#import "FlurryAPI.h"

#define LOGIN_FAILED_ALERT_TAG -1
#define FRIEND_INVITE_ALERT_TAG 1
#define CHAT_ROOM_INVITE_ALERT_TAG 2

@implementation Xblaze_iPhoneAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize splitViewController;
@synthesize contactListController;
@synthesize clansViewController;
@synthesize chatRoomListViewController;
@synthesize username, password;
@synthesize xfSession;
@synthesize friendRequests;
@synthesize unreadFriendsCount = _unreadFriendsCount;
@synthesize unreadClansCount = _unreadClansCount;
@synthesize tabBarController;

- (void)playChatMessageSound
{
	[soundEffect play];
}

#pragma mark -
#pragma mark Application lifecycle

void uncaughtExceptionHandler(NSException *exception)
{
	[FlurryAPI logError:@"Unhandled Exception" message:[exception reason] exception:exception];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	NSLog(@"Device Token: %@", deviceToken);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	NSLog(@"Failed to register for remote notifications: %@", [error localizedDescription]);
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	//[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound];
	//[[UIApplication sharedApplication] unregisterForRemoteNotifications];
	NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
	[FlurryAPI startSession:@"4Q9D27LLLVBAGJBJEU3S"];
	
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	
	NSDictionary *defaultsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kAllowAudioAlerts, [NSNumber numberWithBool:YES], kAllowVibrateAlerts, nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];
	
    activityCount = 0;
	xfSession = nil;
	friendRequests = [[NSMutableArray alloc] init];
	_chatRoomInvites = [[NSMutableArray alloc] init];
	_chatControllers = [[NSMutableArray alloc] init];
	reach = [[Reachability reachabilityWithHostName:XfireHostName] retain];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reachabilityChanged:)
												 name:kReachabilityChangedNotification
											   object:nil];
	[reach startNotifier];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[window addSubview:[splitViewController view]];
	}
	else
	{		
		loginViewController = (XBLoginViewController *)[[navigationController viewControllers] objectAtIndex:0]; // root view controller is at index 0
		[loginViewController retain];																			 // root view controller is login controller
		
		[window addSubview:[navigationController view]];
	}
	
	[window makeKeyAndVisible];
	UIInterfaceOrientation orientation = [[UIDevice currentDevice] orientation];
	UIImage *defaultImage = nil;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		if (UIInterfaceOrientationIsPortrait(orientation))
		{
			defaultImage = [UIImage imageNamed:@"Default-Portrait.png"];
		}
		else if (UIInterfaceOrientationIsLandscape(orientation))
		{
			defaultImage = [UIImage imageNamed:@"Default-Landscape.png"];
		}
	}
	else
	{
		defaultImage = [UIImage imageNamed:@"Default.png"];
	}
	
	logoImage = [[[UIImageView alloc] initWithImage:defaultImage] autorelease];
	[logoImage setContentMode:UIViewContentModeScaleAspectFill];
	
	if (orientation == UIInterfaceOrientationPortraitUpsideDown)
		[logoImage setTransform:CGAffineTransformMakeRotation(M_PI)];
	else if (orientation == UIInterfaceOrientationLandscapeLeft)
		[logoImage setTransform:CGAffineTransformMakeRotation((270 * M_PI) / 180)];
	else if (orientation == UIInterfaceOrientationLandscapeRight)
		[logoImage setTransform:CGAffineTransformMakeRotation((90 * M_PI) / 180)];
		 
	CGRect frame = [logoImage frame];
	frame.origin = CGPointZero;
	[logoImage setFrame:frame];
	CGPoint center = CGPointMake((frame.size.width / 2), (frame.size.height / 2));
	
	
	[window addSubview:logoImage];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(continueFinishLaunching)];
	[UIView setAnimationDuration:0.6];
	frame.size.width = frame.size.width * 1.5;
	frame.size.height = frame.size.height * 1.5;
	CGPoint newCenter = CGPointMake((frame.size.width / 2), (frame.size.height / 2));
	CGPoint difference = CGPointMake((newCenter.x - center.x), (newCenter.y - center.y));
	frame.origin.x = frame.origin.x - difference.x;
	frame.origin.y = frame.origin.y - difference.y;
	[logoImage setFrame:frame];
	[logoImage setAlpha:0.0];
	[UIView commitAnimations];
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Purr" ofType:@"aiff"];
	soundEffect = [[SoundEffect alloc] initWithContentsOfFile:path];
}

- (void)continueFinishLaunching
{
	[logoImage removeFromSuperview];
	[[NSNotificationCenter defaultCenter] postNotificationName:kShowKeyboardNotification object:nil];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		loginViewController = [[XBLoginViewController alloc] initWithNibName:@"XBLoginViewController" bundle:nil];
		[loginViewController setTitle:@"Login to Xblaze"];
		UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:loginViewController] autorelease];
		[[navController navigationBar] setBarStyle:UIBarStyleBlack];
		[navController setModalPresentationStyle:UIModalPresentationFormSheet];
		[navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
		[splitViewController presentModalViewController:navController animated:YES];
	}
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[self disconnect];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[loginViewController connect];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)reachabilityChanged:(NSNotification *)note
{
	if ([reach currentReachabilityStatus] == NotReachable)
	{
		if ([xfSession status] == kXfireSessionStatusOnline)
		{	
			[xfSession disconnect];
			
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No Internet Connection"
															 message:@"You have been disconnected because the network connection was not available."
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] autorelease];
			[alert show];
		}
		
	}
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc
{
	if (friendRequests)
	{
		[friendRequests release];
		friendRequests = nil;
	}
	
	self.password = nil;
	self.username = nil;
	[loginViewController release];
	loginViewController = nil;
	[navigationController release];
	[window release];
	[reach release];
	[xfSession release];
	[_chatControllers release];
	[soundEffect release];
	[super dealloc];
}

#pragma mark Xfire Session Stuff

- (void)connectWithUsername:(NSString *)_username password:(NSString *)_password
{	
	self.username = _username;
	self.password = _password;
	
	[xfSession release];
	//xfSession = [XfireSession newSessionWithIP:self.xfireServerIP port:XfirePortNumber];
	xfSession = [XfireSession newSessionWithHost:XfireHostName port:XfirePortNumber];
	
	[xfSession setDelegate:self];
	[xfSession setPosingClientVersion:XfirePoseClientVersion];
	
	[xfSession connect];
}

- (void)disconnect
{
	[_chatControllers removeAllObjects];
	[friendRequests removeAllObjects];
	[xfSession disconnect];
	[[NSNotificationCenter defaultCenter] postNotificationName:kShowKeyboardNotification object:nil];
}

- (void)finishConnecting
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		[self showTabBarController];
	}
	else
	{
		[splitViewController dismissModalViewControllerAnimated:YES];
		[contactListController setXfSession:xfSession];
		[[contactListController tableView] reloadData];
		[clansViewController setXfSession:xfSession];
		[clansViewController xfSessionDidConnect];
		[chatRoomListViewController setSession:xfSession];
	}
	
	[loginViewController hideConnectingOverlay];
	[self stopNetworkIndicator];	
}

- (void)showTabBarController
{
	XBContactListViewController *contactsListViewController = [[[XBContactListViewController alloc] initWithNibName:@"XBContactListViewController" bundle:nil] autorelease];
	[contactsListViewController setXfSession:xfSession];
	UINavigationController *contactsNavController = [[[UINavigationController alloc] initWithRootViewController:contactsListViewController] autorelease];
	[[contactsNavController tabBarItem] setTitle:@"Friends"];
	[[contactsNavController tabBarItem] setImage:[UIImage imageNamed:@"111-user.png"]];
	[[contactsNavController navigationBar] setBarStyle:UIBarStyleBlack];
	contactListController = contactsListViewController;
		
	XBChatRoomListViewController *chatRoomsListViewController = [[[XBChatRoomListViewController alloc] initWithNibName:@"XBChatRoomListViewController" bundle:nil] autorelease];
	UINavigationController *chatRoomNavController = [[[UINavigationController alloc] initWithRootViewController:chatRoomsListViewController] autorelease];
	[[chatRoomNavController tabBarItem] setTitle:@"Chat Rooms"];
	[[chatRoomNavController tabBarItem] setImage:[UIImage imageNamed:@"112-group.png"]];
	[[chatRoomNavController navigationBar] setBarStyle:UIBarStyleBlack];
	chatRoomListViewController = chatRoomsListViewController;
	
	XBClansViewController *clanListViewController = [[[XBClansViewController alloc] initWithNibName:@"XBClansViewController" bundle:nil] autorelease];
	UINavigationController *clansNavController = [[[UINavigationController alloc] initWithRootViewController:clanListViewController] autorelease];
	[[clansNavController tabBarItem] setTitle:@"Communities"];
	[[clansNavController tabBarItem] setImage:[UIImage imageNamed:@"101-gameplan.png"]];
	[[clansNavController navigationBar] setBarStyle:UIBarStyleBlack];
	[clanListViewController view]; // force views to load
	
	XBSettingsViewController *settingsController = [[[XBSettingsViewController alloc] initWithNibName:@"XBSettingsViewController" bundle:nil] autorelease];
	UINavigationController *settingsNavController = [[[UINavigationController alloc] initWithRootViewController:settingsController] autorelease];
	[[settingsNavController tabBarItem] setTitle:@"Settings"];
	[[settingsNavController tabBarItem] setImage:[UIImage imageNamed:@"20-gear2.png"]];
	[[settingsNavController navigationBar] setBarStyle:UIBarStyleBlack];
	
	tabBarController = [[[UITabBarController alloc] init] autorelease];
	tabBarController.viewControllers = [NSArray arrayWithObjects:contactsNavController, chatRoomNavController, clansNavController, settingsNavController, nil];
	
	[loginViewController presentModalViewController:tabBarController animated:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateUnreadCounter:)
												 name:kMessageReceivedNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateUnreadCounter:)
												 name:kContactListControllerDidAppear
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateUnreadCounter:)
												 name:kClansListControllerDidAppear
											   object:nil];
	
	//[self runTestMethod];
}

- (void)pushViewControllerWithAnimation:(UIViewController *)viewController
{
	[self.navigationController pushViewController:viewController animated:YES];
}

//- (void)runTestMethod
//{
//	XfireFriend *me = [xfSession loginIdentity];
//	NSData *sid = [me sessionID];
//	NSString *sidAsString = [sid stringRepresentation];
//	
//	NSData *shaOfSalt = [[@"[14:17] =HT=Gamma: never heard anything back regarding getting activity report" dataUsingEncoding:NSUTF8StringEncoding] sha1Hash];
//	NSString *shaOfSaltAsString = [shaOfSalt stringRepresentation];
//	
//	NSData *sidAndHashedSalt = [[NSString stringWithFormat:@"%@%@", sidAsString, shaOfSaltAsString] dataUsingEncoding:NSUTF8StringEncoding];
//	NSData *hashedSidWithHashedSalt = [sidAndHashedSalt sha1Hash];
//	NSString *signature = [hashedSidWithHashedSalt stringRepresentation];
//	
//	DebugLog(@"Final result: %@", signature);
//	DebugLog(@"http://www.xfire.com/client/activity_report.php?userid=%u&signature=%@&third_party=xblaze", [me userID], signature);
//}

- (void)startNetworkIndicator
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	activityCount++;
}

- (void)stopNetworkIndicator
{
	if (activityCount > 0)
		activityCount--;
	
	if (activityCount == 0)
	{
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}

#pragma mark XfireSession Delegate

- (void)xfireGetSession:(XfireSession *)session userName:(NSString **)aName password:(NSString **)aPassword
{
	*aName = [self.username copy];
	*aPassword = [self.password copy];
}

- (XfireSkin *)xfireSessionSkin:(XfireSession *)session
{
	return [XfireSkin theSkin];
}

- (void)xfireSession:(XfireSession *)session didChangeStatus:(XfireSessionStatus)newStatus
{
	switch (newStatus) {
		case kXfireSessionStatusOffline:
			[loginViewController hideConnectingOverlay];
			break;
		case kXfireSessionStatusOnline:
			[self finishConnecting];
			break;
		case kXfireSessionStatusGettingFriends:
			[loginViewController setOverlayMessage:@"Getting friends..."];
		case kXfireSessionStatusLoggingOn:
			break;
		case kXfireSessionStatusLoggingOff:
			break;
		default:
			break;
	}
}

- (void)xfireSessionLoginFailed:(XfireSession *)session reason:(NSString *)reason
{	
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Login Failed"
													 message:reason
													delegate:nil
										   cancelButtonTitle:nil
										   otherButtonTitles:@"OK", nil] autorelease];
	[alert show];
	[self stopNetworkIndicator];
	[loginViewController hideConnectingOverlay];
	[[NSNotificationCenter defaultCenter] postNotificationName:kShowKeyboardNotification object:nil];
}

- (void)showLoginView
{
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:loginViewController] autorelease];
	[[navController navigationBar] setBarStyle:UIBarStyleBlack];
	[navController setModalPresentationStyle:UIModalPresentationFormSheet];
	[navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
	[splitViewController presentModalViewController:navController animated:YES];
}

- (void)xfireSessionWillDisconnect:(XfireSession *)session reason:(NSString *)reason
{
	[_chatControllers removeAllObjects];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		[self.navigationController dismissModalViewControllerAnimated:YES];
	}
	else
	{
		[contactListController setXfSession:nil];
		[[contactListController tableView] reloadData];
		[[chatRoomListViewController chatRooms] removeAllObjects];
		[self updateChatViewControllerWithChatController:nil];
		[[chatRoomListViewController tableView] reloadData];
		[chatRoomListViewController setSession:nil];
		
		[splitViewController dismissModalViewControllerAnimated:YES];
		
		[self performSelector:@selector(showLoginView) withObject:nil afterDelay:0.5];
	}
	
	if ([reason isEqualToString:kXfireNormalDisconnectReason])
	{
		return;
	}
	
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Disconnected"
													 message:reason
													delegate:nil
										   cancelButtonTitle:nil
										   otherButtonTitles:@"OK", nil] autorelease];
	[alert show];
}

- (void)xfireSession:(XfireSession *)session friendDidChange:(XfireFriend *)fr attribute:(XfireFriendChangeAttribute)attr
{
	XBChatController *chatController = [self chatControllerForFriend:fr];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:fr, @"friend", [NSNumber numberWithInt:attr], @"attribute", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireFriendDidChangeNotification object:chatController userInfo:dict];
	
	if (attr == kXfireFriendWasRemoved)
	{
		if (chatController)
		{
			[self.xfSession closeChat:[chatController chat]];
		}
	}
}

- (void)xfireSession:(XfireSession *)session friendGroupDidChange:(XfireFriendGroup *)grp
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:grp forKey:@"group"];
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireFriendGroupDidChangeNotification object:nil userInfo:userInfo];
}

- (void)xfireSession:(XfireSession *)session friendGroupWasAdded:(XfireFriendGroup *)grp
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:grp forKey:@"group"];
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireFriendGroupWasAddedNotification object:nil userInfo:userInfo];	
}

- (void)xfireSession:(XfireSession *)session friendGroupWillBeRemoved:(XfireFriendGroup *)grp
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:grp forKey:@"group"];
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireFriendGroupWillBeRemovedNotification object:nil userInfo:userInfo];
}

- (void)xfireSession:(XfireSession *)session didBeginChat:(XfireChat *)chat
{
	[xfSession requestInfoViewInfoForFriend:[chat remoteFriend]];
	XBChatController *chatController = [[XBChatController alloc] initWithXfireSession:session chat:chat];
	[_chatControllers addObject:chatController];
	[chatController release];
	
	NSDictionary * userInfo = [NSDictionary dictionaryWithObject:chatController forKey:@"chatController"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireDidBeginChatNotification
														object:self
													  userInfo:userInfo];
}

- (void)xfireSession:(XfireSession *)session chatDidEnd:(XfireChat *)aChat
{
	XBChatController *chatController = [self chatControllerForFriend:[aChat remoteFriend]];
	[[chatController retain] autorelease];
	[_chatControllers removeObject:chatController];
	
	NSDictionary * userInfo = [NSDictionary dictionaryWithObject:chatController forKey:@"chatController"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireDidEndChatNotification
														object:self
													  userInfo:userInfo];
}

- (void)xfireSessionJoinChatRoomPasswordRequired:(XfireSession *)session
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireJoinChatRoomPasswordRequiredNotification object:nil];
}

- (void)xfireSessionJoinChatRoomInvalidPassword:(XfireSession *)session
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireJoinChatRoomInvalidPasswordNotification object:nil];
}

- (void)xfireSession:(XfireSession *)session didJoinChatRoom:(XfireChatRoom *)chatRoom
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireDidJoinChatRoomNotification object:chatRoom userInfo:nil];
}

- (void)xfireSession:(XfireSession *)session updatedInfoForChatRoom:(XfireChatRoom *)chatRoom
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireUpdatedChatRoomInfoNotification object:chatRoom userInfo:nil];
}

- (void)xfireSession:(XfireSession *)session user:(XfireFriend *)user didJoinChatRoom:(XfireChatRoom *)chatRoom
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:user, @"friend", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireFriendDidJoinChatRoomNotification object:chatRoom userInfo:userInfo];
}

- (void)xfireSession:(XfireSession *)session userDidLeaveChatRoom:(XfireChatRoom *)chatRoom
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireUserDidLeaveChatRoomNotification object:chatRoom userInfo:nil];
}

- (void)xfireSession:(XfireSession *)session receivedInviteFromFriend:(XfireFriend *)friend forChatRoom:(XfireChatRoom *)chatRoom
{
	[_chatRoomInvites addObject:chatRoom];
	
	UIAlertView *chatRoomInviteAlert = [[[UIAlertView alloc] initWithTitle:@"Chat Room Invite"
																   message:[NSString stringWithFormat:@"%@ would like you to join the chat room: \"%@\"", [friend displayName], [chatRoom name]]
																  delegate:self
														 cancelButtonTitle:@"Decline"
														 otherButtonTitles:@"Accept", nil] autorelease];
	[chatRoomInviteAlert setTag:(CHAT_ROOM_INVITE_ALERT_TAG + [_chatRoomInvites indexOfObject:chatRoom])];
	[chatRoomInviteAlert show];
}

- (void)xfireSession:(XfireSession *)session user:(XfireFriend *)user kickedFromChatRoom:(XfireChatRoom *)chatRoom
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:user forKey:@"user"];
	[[NSNotificationCenter defaultCenter] postNotificationName:kXfireUserKickedFromChatRoomNotification object:chatRoom userInfo:userInfo];
}

- (NSArray *)chatControllers
{
	return [[_chatControllers copy] autorelease];
}

- (XBChatController *)chatControllerForFriend:(XfireFriend *)friend
{
	XBChatController *chatControllerToReturn = nil;
	
	for (XBChatController *chatController in _chatControllers)
	{
		if ([[[chatController chat] remoteFriend] compareFriendsByUserName:friend] == NSOrderedSame)
		{
			chatControllerToReturn = chatController;
		}
	}
	
	return chatControllerToReturn;
}

- (void)beginUserSearch:(NSString *)searchString
{
	[self.xfSession beginUserSearch:searchString];
}

- (void)xfireSession:(XfireSession *)session searchResults:(NSArray *)friends
{
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kSearchCompleteNotification object:friends]];
}

- (void)xfireSession:(XfireSession *)session didReceiveFriendshipRequests:(NSArray *)requestors
{	
	[self.friendRequests addObjectsFromArray:requestors];
	
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Friend Requests"
													 message:[NSString stringWithFormat:@"You have %d outstanding friend requests", [self.friendRequests count]]
													delegate:self
										   cancelButtonTitle:@"Ignore"
										   otherButtonTitles:@"Show Me!", nil] autorelease];
	[alert setTag:FRIEND_INVITE_ALERT_TAG];
	[alert show];
}

- (void)acceptFriendRequest:(XfireFriend *)request
{
	[self.xfSession acceptFriendRequest:request];
	[self.friendRequests removeObject:request];
}

- (void)declineFriendRequest:(XfireFriend *)request
{
	[self.xfSession declineFriendRequest:request];
	[self.friendRequests removeObject:request];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{	
	if ([alertView tag] == FRIEND_INVITE_ALERT_TAG)
	{
		if (buttonIndex != [alertView cancelButtonIndex])
		{
			[contactListController showInvites];
		}
	}
	else if ([alertView tag] >= CHAT_ROOM_INVITE_ALERT_TAG)
	{
		if (buttonIndex == [alertView cancelButtonIndex])
		{
			NSInteger index = [alertView tag] - CHAT_ROOM_INVITE_ALERT_TAG;
			XfireChatRoom *chatRoom = [_chatRoomInvites objectAtIndex:index];
			[xfSession declineChatRoomInviteForChatRoom:chatRoom];
			[_chatRoomInvites removeObject:chatRoom];
		}
		else
		{
			NSInteger index = [alertView tag] - CHAT_ROOM_INVITE_ALERT_TAG;
			XfireChatRoom * chatRoom = [_chatRoomInvites objectAtIndex:index];
			
			if ([chatRoom chatRoomAccess] == XFGroupChatAccessFriends)
			{
				[self.chatRoomListViewController getPasswordAndJoinChatRoom:chatRoom];
			}
			else
			{
				[xfSession joinChatRoom:chatRoom];
			}
			
			[_chatRoomInvites removeObject:chatRoom];
		}
	}
}

- (void)updateChatViewControllerWithChatController:(XBChatController *)chatController
{
	XBChatViewController *chatViewController = [[[[splitViewController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
	[chatViewController setChatController:chatController];
}

- (XBChatController *)activeChatController
{
	XBChatViewController *chatViewController = [[[[splitViewController viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
	return [chatViewController chatController];
}

- (void)updateUnreadCounter:(NSNotification *)note
{
	_unreadFriendsCount = 0;
	_unreadClansCount = 0;
	
	for (XBChatController *chatController in _chatControllers)
	{
		if ([[[chatController chat] remoteFriend] isDirectFriend])
			_unreadFriendsCount += [chatController unreadCount];
		else if ([[[chatController chat] remoteFriend] isClanMember])
			_unreadClansCount += [chatController unreadCount];
	}
	
	if (_unreadFriendsCount > 0)
	{
		[[[[tabBarController viewControllers] objectAtIndex:0] tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%d",_unreadFriendsCount]];
	}
	else
	{
		[[[[tabBarController viewControllers] objectAtIndex:0] tabBarItem] setBadgeValue:nil];
	}
	
	if (_unreadClansCount > 0)
	{
		[[[[tabBarController viewControllers] objectAtIndex:2] tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%d",_unreadClansCount]];
	}
	else
	{
		[[[[tabBarController viewControllers] objectAtIndex:2] tabBarItem] setBadgeValue:nil];
	}
}

@end

