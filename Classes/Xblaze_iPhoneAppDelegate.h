//
//  Xblaze_iPhoneAppDelegate.h
//  Xblaze-iPhone
//
//  Created by James on 12/11/2009.
//  Copyright JamSoft 2009. All rights reserved.
//

#import "XfireSession.h"
#import "Reachability.h"
#import "XBChatController.h"
#import "SoundEffect.h"
#import "XBLoginViewController.h"
#import "XBContactListViewController.h"
#import "XBPushManager.h"

@class XBContactListViewController, XBClansViewController, XBChatRoomListViewController;

@interface Xblaze_iPhoneAppDelegate : NSObject <UIApplicationDelegate, XBContactListDelegate, XBPushManagerDelegate> {    

    UIWindow *window;
    UINavigationController *navigationController;
	UISplitViewController *splitViewController;
	UITabBarController *tabBarController;
	
	UIImageView *logoImage;
	int activityCount;
	
	XfireSession *xfSession;
	
	NSString *username, *password;
	
	NSMutableArray *_chatControllers;
	NSMutableArray *friendRequests;
	
	NSMutableArray *_chatRoomInvites;
	
	SoundEffect *soundEffect;
	
	XBLoginViewController *loginViewController;
	XBContactListViewController *contactListController;
	XBClansViewController *clansViewController;
	XBChatRoomListViewController *chatRoomListViewController;
	
	Reachability *reach;
	
	NSInteger _unreadFriendsCount;
	NSInteger _unreadClansCount;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
@property (nonatomic, retain) UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet XBContactListViewController *contactListController;
@property (nonatomic, retain) IBOutlet XBClansViewController *clansViewController;
@property (nonatomic, retain) IBOutlet XBChatRoomListViewController *chatRoomListViewController;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, readonly) XfireSession *xfSession;
@property (nonatomic, readonly) NSMutableArray *friendRequests;
@property (nonatomic, assign) NSInteger unreadFriendsCount;
@property (nonatomic, assign) NSInteger unreadClansCount;

- (void)continueFinishLaunching;

- (void)connectWithUsername:(NSString *)_username password:(NSString *)_password;
- (void)disconnect;

- (void)showTabBarController;

- (void)beginUserSearch:(NSString *)searchString;

- (NSArray *)chatControllers;
- (XBChatController *)chatControllerForFriend:(XfireFriend *)friend;

- (void)playChatMessageSound;

- (void)acceptFriendRequest:(XfireFriend *)request;
- (void)declineFriendRequest:(XfireFriend *)request;

- (void)updateUnreadCounter:(NSNotification *)note;
- (void)showLoginView;

//- (void)runTestMethod;
@end

