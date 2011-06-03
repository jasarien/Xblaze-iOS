//
//  XBChatRoomViewController.h
//  Xblaze-iPhone
//
//  Created by James on 28/08/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XfireChatRoom.h"
#import "SoundEffect.h"
#import "XBChatMessageCell.h"

@class XfireSession;

@interface XBChatRoomViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, XfireChatRoomDelegate, UITextFieldDelegate, XBChatMessageCellDelegate> {

	UITableView *_tableView;
	UIToolbar *_toolbar;
	UITextField *_textField;
	
	XfireChatRoom *_chatRoom;
	XfireSession *_session;
	
	NSMutableArray *_messages;
	NSArray *_tempLinks;
	
	UIActionSheet *_optionsActionSheet;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UITextField *textField;

@property (nonatomic, retain) XfireChatRoom *chatRoom;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil session:(XfireSession *)session chatRoom:(XfireChatRoom *)chatRoom;

- (void)handleXfireUserKickedFromChatRoomNotification:(NSNotification *)note;

- (IBAction)dimissKeyboard:(id)sender;
- (void)options:(id)sender;
- (void)dismiss:(id)sender;

@end
