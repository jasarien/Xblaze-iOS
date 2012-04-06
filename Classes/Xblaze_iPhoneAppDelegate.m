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
#import "XBClanListViewController.h"
#import "NSData_XfireAdditions.h"
#import "XBDetailViewController.h"
#import "XBChatViewController.h"
#import "XBChatRoomListViewController.h"
#import "XBChatRoomViewController.h"
#import "XfireFriend.h"
#import "XfireChatRoom.h"
#import "FlurryAnalytics.h"
#import "XBNetworkActivityIndicatorManager.h"

#define LOGIN_FAILED_ALERT_TAG -1
#define FRIEND_INVITE_ALERT_TAG 1
#define CHAT_ROOM_INVITE_ALERT_TAG 2

@implementation Xblaze_iPhoneAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize splitViewController;
@synthesize loginViewController;
@synthesize contactListController;
@synthesize clansViewController;
@synthesize chatRoomListViewController;
@synthesize settingsViewController;
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
	[FlurryAnalytics logError:@"Unhandled Exception" message:[exception reason] exception:exception];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	NSLog(@"Device Token: %@", deviceToken);
	
	NSString *pushToken = [deviceToken stringRepresentation];
	[[XBPushManager sharedInstance] setPushToken:pushToken];
	
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	NSLog(@"Failed to register for remote notifications: %@", [error localizedDescription]);
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	[[XBPushManager sharedInstance] setDelegate:self];
	
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound];
	
//	[[UIApplication sharedApplication] unregisterForRemoteNotifications];
	NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
	[FlurryAnalytics startSession:@"4Q9D27LLLVBAGJBJEU3S"];
	
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
		[window setRootViewController:self.splitViewController];
	}
	else
	{		
		[self showTabBarController];
	}
	
	[window makeKeyAndVisible];
	UIInterfaceOrientation orientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
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
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	_goingIntoBackground = YES;
	[self disconnect];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[self.loginViewController connect];
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
			[xfSession disconnectWithReason:kXfireNormalDisconnectReason];
			
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No Internet Connection"
															 message:@"You have been disconnected because the network connection was not available."
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] autorelease];
			[alert show];
		}
		
	}
}

#pragma mark - XBPushManagerDelegate

- (void)pushManagerDidRegister:(XBPushManager *)pushManager
{
	[[XBPushManager sharedInstance] downloadMissedMessages];
}

- (void)pushManager:(XBPushManager *)pushManager didFailToRegisterWithError:(NSError *)error
{
	
}

- (void)pushManagerDidUnregister:(XBPushManager *)pushManager
{
	
}

- (void)pushManager:(XBPushManager *)pushManager didFailToUnregisterWithError:(NSError *)error
{
	
}

- (void)pushManagerDidUnregisterDevice:(XBPushManager *)pushManager
{
	
}

- (void)pushManager:(XBPushManager *)pushManager didFailToUnregisterDeviceWithError:(NSError *)error
{
	
}

- (void)pushManager:(XBPushManager *)pushManager didLoadMissedMessages:(NSArray *)missedMessages
{
	for (NSDictionary *missedMessage in missedMessages)
	{
		NSString *chatUsername = [missedMessage objectForKey:@"username"];
		NSString *message = [missedMessage objectForKey:@"message"];
		NSDate *date = [missedMessage objectForKey:@"date"];
		
		XfireFriend *friend = [self.xfSession friendForUserName:chatUsername];
		if (friend)
		{
			XfireChat *chat = [self.xfSession chatForSessionID:[friend sessionID]];
			if (!chat)
			{
				chat = [self.xfSession beginChatWithFriend:friend];
			}
		}
		
		XBChatController *chatController = [self chatControllerForFriend:friend];
		[[chatController chatMessages] addObject:[NSDictionary dictionaryWithObjectsAndKeys:chatUsername, kChatIdentityKey, message, kChatMessageKey, date, kChatDateKey, nil]];
	}
}

- (void)pushManager:(XBPushManager *)pushManager didFailToLoadMissedMessagesWithError:(NSError *)error
{
	
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
	self.loginViewController = nil;
	self.contactListController = nil;
	self.clansViewController = nil;
	self.chatRoomListViewController = nil;
	self.settingsViewController = nil;
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
	xfSession = [XfireSession newSessionWithHost:XfireHostName port:XfirePortNumber];
	
	[xfSession setDelegate:self];
	[xfSession setPosingClientVersion:XfirePoseClientVersion];
	
	[xfSession connect];
}

- (void)disconnect
{
	[_chatControllers removeAllObjects];
	[friendRequests removeAllObjects];
	[xfSession disconnectWithReason:kXfireNormalDisconnectReason];
	[[NSNotificationCenter defaultCenter] postNotificationName:kShowKeyboardNotification object:nil];
	
	[[XBPushManager sharedInstance] connectToServer];
}

- (void)finishConnecting
{
	[[window rootViewController] dismissModalViewControllerAnimated:YES];
	
	[contactListController setXfSession:xfSession];
	[[contactListController tableView] reloadData];
	[clansViewController setXfSession:xfSession];
	[clansViewController xfSessionDidConnect];
	[chatRoomListViewController setSession:xfSession];
	[chatRoomListViewController xfSessionDidConnect];
	[settingsViewController setXfSession:xfSession];
	[settingsViewController refreshSettings];
	
	[self.loginViewController hideConnectingOverlay];
	[XBNetworkActivityIndicatorManager hideNetworkActivity];
	
	NSString *passwordHash = [NSString stringWithFormat:@"%@%@UltimateArena", username, password];
	passwordHash = [[[passwordHash dataUsingEncoding:NSUTF8StringEncoding] sha1Hash] stringRepresentation];
	
	[[XBPushManager sharedInstance] setUsername:username];
	[[XBPushManager sharedInstance] setPasswordHash:passwordHash];
	[[XBPushManager sharedInstance] registerToServer];
}

- (void)showTabBarController
{
	XBContactListViewController *contactsListViewController = [[[XBContactListViewController alloc] initWithNibName:@"XBContactListViewController" bundle:nil] autorelease];
	[contactsListViewController setXfSession:xfSession];
	UINavigationController *contactsNavController = [[[UINavigationController alloc] initWithRootViewController:contactsListViewController] autorelease];
	[[contactsNavController tabBarItem] setTitle:@"Friends"];
	[[contactsNavController tabBarItem] setImage:[UIImage imageNamed:@"111-user.png"]];
	[[contactsNavController navigationBar] setBarStyle:UIBarStyleBlack];
	self.contactListController = contactsListViewController;
		
	XBChatRoomListViewController *chatRoomsListViewController = [[[XBChatRoomListViewController alloc] initWithNibName:@"XBChatRoomListViewController" bundle:nil] autorelease];
	UINavigationController *chatRoomNavController = [[[UINavigationController alloc] initWithRootViewController:chatRoomsListViewController] autorelease];
	[[chatRoomNavController tabBarItem] setTitle:@"Chat Rooms"];
	[[chatRoomNavController tabBarItem] setImage:[UIImage imageNamed:@"112-group.png"]];
	[[chatRoomNavController navigationBar] setBarStyle:UIBarStyleBlack];
	self.chatRoomListViewController = chatRoomsListViewController;
	
	XBClansViewController *clanListViewController = [[[XBClansViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
	UINavigationController *clansNavController = [[[UINavigationController alloc] initWithRootViewController:clanListViewController] autorelease];
	[[clansNavController tabBarItem] setTitle:@"Communities"];
	[[clansNavController tabBarItem] setImage:[UIImage imageNamed:@"101-gameplan.png"]];
	[[clansNavController navigationBar] setBarStyle:UIBarStyleBlack];
	[clanListViewController view]; // force views to load
	self.clansViewController = clanListViewController;
	
	XBSettingsViewController *settingsController = [[[XBSettingsViewController alloc] initWithNibName:@"XBSettingsViewController" bundle:nil] autorelease];
	UINavigationController *settingsNavController = [[[UINavigationController alloc] initWithRootViewController:settingsController] autorelease];
	[[settingsNavController tabBarItem] setTitle:@"Settings"];
	[[settingsNavController tabBarItem] setImage:[UIImage imageNamed:@"20-gear2.png"]];
	[[settingsNavController navigationBar] setBarStyle:UIBarStyleBlack];
	self.settingsViewController = settingsController;
	
	self.tabBarController = [[[UITabBarController alloc] init] autorelease];
	self.tabBarController.viewControllers = [NSArray arrayWithObjects:contactsNavController, chatRoomNavController, clansNavController, settingsNavController, nil];
	
	[window setRootViewController:tabBarController];
	
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
			[self.loginViewController hideConnectingOverlay];
			[[XBPushManager sharedInstance] stopHeartbeat];
			break;
		case kXfireSessionStatusOnline:
			[self finishConnecting];
			break;
		case kXfireSessionStatusGettingFriends:
			[self.loginViewController setOverlayMessage:@"Getting friends..."];
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
	[XBNetworkActivityIndicatorManager hideNetworkActivity];
	[self.loginViewController hideConnectingOverlay];
	[[NSNotificationCenter defaultCenter] postNotificationName:kShowKeyboardNotification object:nil];
}

- (void)showLoginView
{
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:self.loginViewController] autorelease];
	[[navController navigationBar] setBarStyle:UIBarStyleBlack];
	[navController setModalPresentationStyle:UIModalPresentationFormSheet];
	[navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
	[[self.window rootViewController] presentModalViewController:navController animated:YES];
}

- (void)xfireSessionWillDisconnect:(XfireSession *)session reason:(NSString *)reason
{
	[[window rootViewController] dismissModalViewControllerAnimated:YES];
	
	[_chatControllers removeAllObjects];
	[contactListController setXfSession:nil];
	[[contactListController tableView] reloadData];
	[[chatRoomListViewController chatRooms] removeAllObjects];
	[[chatRoomListViewController tableView] reloadData];
	[chatRoomListViewController setSession:nil];
	if (_goingIntoBackground == NO)
	{
		[self showLoginView];
	}
	_goingIntoBackground = NO;
	
	if ([reason isEqualToString:kXfireNormalDisconnectReason])
	{
		[[XBPushManager sharedInstance] connectToServer];
	}
	else
	{
		if ([reason isEqualToString:kXfireOtherSessionReason])
		{
			[[XBPushManager sharedInstance] sendKillHeartbeatToServer];
		}
		else
		{
			[[XBPushManager sharedInstance] connectToServer];
		}
		
		if ([reason isEqualToString:kXfireInvalidPasswordReason] == NO)
		{
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Disconnected"
															 message:reason
															delegate:nil
												   cancelButtonTitle:nil
												   otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
		}
	}
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
//	[chatController saveChatTranscript];
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

