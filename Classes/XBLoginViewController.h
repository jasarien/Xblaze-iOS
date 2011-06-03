//
//  XBLoginViewController.h
//  Xblaze-iPhone
//
//  Created by James on 12/11/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFGenericTableViewController.h"
#import "IFTextCellController.h"
#import "Reachability.h"
#import <MessageUI/MessageUI.h>

extern NSString *kUsernameKey;
extern NSString *kPasswordKey;
extern NSString *kRememberKey;

@class MBProgressHUD;

@interface XBLoginViewController : IFGenericTableViewController <UIAlertViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
	
	MBProgressHUD *_hud;
	
	Reachability *reach;
	
	UIActionSheet *_helpSheet;
	
}

- (void)showConnectingOverlay;
- (void)hideConnectingOverlay;

- (void)nextField;
- (void)connect;
- (void)disconnect;
- (void)toggleSaveCredentials;
- (void)saveUsername:(NSString *)usernameToSave password:(NSString *)passwordToSave;
- (NSString *)retrievePasswordForUsername:(NSString *)savedUsername;
- (void)deleteSavedLoginDetails;
- (void)hideKeyboard;
- (void)showKeyboard:(NSNotification *)note;

- (NSMutableDictionary *)newBaseDictionaryWithServer:(NSString *)server account:(NSString *)account;

- (void)setOverlayMessage:(NSString *)message;
@end
