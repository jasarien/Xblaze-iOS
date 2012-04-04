//
//  XBChatRoomViewController.m
//  Xblaze-iPhone
//
//  Created by James on 28/08/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBChatRoomViewController.h"
#import "XBChatRoomUsersViewController.h"
#import "XBChatRoomInviteViewController.h"
#import "XfireSession.h"
#import "XBWebViewController.h"
#import "AutoHyperlinks.h"
#import "XfireFriend.h"

#define CHAT_ROOM_OPTION_ACTIONSHEET_TAG 1

@interface XBChatRoomViewController ()

- (void)inviteFriend;
- (void)showUsers;

- (void)animateBarUp:(NSNotification *)note;
- (void)animateBarDown:(NSNotification *)note;
- (void)scrollTableToBottomAnimated:(BOOL)animated;

- (void)reset;


@end


@implementation XBChatRoomViewController

@synthesize tableView = _tableView;
@synthesize toolbar = _toolbar;
@synthesize textField = _textField;

@synthesize chatRoom = _chatRoom;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil session:(XfireSession *)session chatRoom:(XfireChatRoom *)chatRoom
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		_chatRoom = [chatRoom retain];
		[self.chatRoom setDelegate:self];
		_session = session;
		_messages = [[NSMutableArray alloc] init];
		[_messages addObjectsFromArray:[self.chatRoom messages]];
		self.hidesBottomBarWhenPushed = YES;
    }
	
    return self;
}

- (void)setChatRoom:(XfireChatRoom *)chatRoom
{
	[_chatRoom release];
	_chatRoom = [chatRoom retain];
	
	[self reset];
}

- (void)reset
{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:kXfireUserKickedFromChatRoomNotification
												  object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleXfireUserKickedFromChatRoomNotification:)
												 name:kXfireUserKickedFromChatRoomNotification
											   object:self.chatRoom];
	
	self.title = [[self.chatRoom name] capitalizedString];	
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = [[self.chatRoom name] capitalizedString];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"19-gear.png"]
																			   style:UIBarButtonItemStyleBordered
																			  target:self
																			  action:@selector(options:)] autorelease];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Back"
																				  style:UIBarButtonItemStyleBordered
																				 target:self
																				 action:@selector(dismiss:)] autorelease];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(animateBarUp:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(animateBarDown:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleXfireUserKickedFromChatRoomNotification:)
												 name:kXfireUserKickedFromChatRoomNotification
											   object:self.chatRoom];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[self.chatRoom setUnreadCount:0];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		[_textField becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.tableView = nil;
	self.toolbar = nil;
	self.textField = nil;
}

- (void)dealloc
{
	[self viewDidUnload];
	[self.chatRoom setDelegate:nil];
	[_chatRoom release], _chatRoom = nil;
	_session = nil;
	[_messages release], _messages = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)handleXfireUserKickedFromChatRoomNotification:(NSNotification *)note
{
	XfireFriend *user = [[note userInfo] objectForKey:@"user"];
	if ([user userID] == [[_session loginIdentity] userID])
	{
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
	else
	{
		NSString *text = [NSString stringWithFormat:@"%@ was kicked from the chat room", [user displayName]];
		NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:@"system", @"system", text, @"message", nil];
		[[self.chatRoom messages] addObject:message];	
		[_messages addObject:message];
		[self.tableView reloadData];
		[self scrollTableToBottomAnimated:YES];
	}
}

- (IBAction)dimissKeyboard:(id)sender
{
	[self.textField resignFirstResponder];
}

- (void)dismiss:(id)sender
{
	if (_optionsActionSheet)
	{
		[_optionsActionSheet dismissWithClickedButtonIndex:[_optionsActionSheet cancelButtonIndex] animated:YES];
	}
	
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)options:(id)sender
{
	if (_optionsActionSheet)
		return;
	
	_optionsActionSheet = [[[UIActionSheet alloc] initWithTitle:@"Chat Room Options"
															  delegate:self
													 cancelButtonTitle:@"Cancel"
												destructiveButtonTitle:nil
													 otherButtonTitles:@"Manage Users", nil] autorelease];
	[_optionsActionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
	[_optionsActionSheet setTag:CHAT_ROOM_OPTION_ACTIONSHEET_TAG];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
			[_optionsActionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
	}
	else
	{
		[_optionsActionSheet showInView:self.view];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [actionSheet cancelButtonIndex])
	{
		[self showUsers];
	}
	
	_optionsActionSheet = nil;
}

- (void)inviteFriend
{
	XBChatRoomInviteViewController *inviteViewController = [[[XBChatRoomInviteViewController alloc] initWithNibName:@"XBChatRoomInviteViewController"
																											 bundle:nil
																										   chatRoom:self.chatRoom] autorelease];
	[self.navigationController pushViewController:inviteViewController animated:YES];
	
}

- (void)showUsers
{
	XBChatRoomUsersViewController *chatRoomUsersViewController = [[[XBChatRoomUsersViewController alloc] initWithNibName:@"XBChatRoomUsersViewController"
																												  bundle:nil
																												   chatRoom:self.chatRoom] autorelease];
	[self.navigationController pushViewController:chatRoomUsersViewController animated:YES];
}

- (void)animateBarUp:(NSNotification *)note
{
	CGRect keyboardBounds;
	[[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
	
	keyboardBounds = [self.view convertRect:keyboardBounds fromView:[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] window]];
	
	CGRect toolbarRect = self.toolbar.frame;
	CGRect tableRect = [self.tableView frame];
	
	toolbarRect.origin.y = keyboardBounds.origin.y - toolbarRect.size.height;
	tableRect.size.height = toolbarRect.origin.y;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[self.toolbar setFrame:toolbarRect];
	[self.tableView setFrame:tableRect];
	[UIView commitAnimations];
	
	[self scrollTableToBottomAnimated:NO];
}

- (void)animateBarDown:(NSNotification *)note
{
	CGRect keyboardBounds;
	[[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
	
	keyboardBounds = [self.view convertRect:keyboardBounds fromView:[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] window]];
	
	CGRect toolbarRect = self.toolbar.frame;
	CGRect tableRect = [self.tableView frame];
	
	toolbarRect.origin.y = keyboardBounds.origin.y - toolbarRect.size.height;
	tableRect.size.height = toolbarRect.origin.y;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[self.toolbar setFrame:toolbarRect];
	[self.tableView setFrame:tableRect];
	[UIView commitAnimations];
}

- (void)scrollTableToBottomAnimated:(BOOL)animated
{
	if ([_messages count] > 1)
	{
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([_messages count] - 1) inSection:0];
		[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
	}
}

- (void)session:(XfireSession *)session chatRoom:(XfireChatRoom *)chatRoom didReceiveMessage:(NSDictionary *)message
{
	[_messages addObject:message];
	[self.tableView reloadData];
	[self scrollTableToBottomAnimated:YES];
}

- (void)session:(XfireSession *)session chatRoom:(XfireChatRoom *)chatRoom didReceiveSystemMessage:(NSDictionary *)message
{
	[_messages addObject:message];
	[self.tableView reloadData];
	[self scrollTableToBottomAnimated:YES];
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ([[_textField text] length])
	{
		[self.chatRoom sendMessage:[_textField text]];
		[_textField setText:nil];
	}
	
	return YES;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([[_messages objectAtIndex:[indexPath row]] objectForKey:@"system"])
	{
		static NSString *CellID = @"SystemMessageCell";
		
		UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellID];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellID] autorelease];
		}
		
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.textLabel.textColor = [UIColor grayColor];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:13];
		cell.textLabel.text = [[_messages objectAtIndex:[indexPath row]] objectForKey:@"message"];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		return cell;
	}
		
	
    static NSString *CellIdentifier = @"XfireMessageCell";
    
    XBChatMessageCell *cell = (XBChatMessageCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[XBChatMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	NSDictionary *chatMessage = [_messages objectAtIndex:[indexPath row]];
	NSString *username = [[chatMessage objectForKey:@"user"] displayName];
	NSString *message = [chatMessage objectForKey:@"message"];
	
	BOOL showTimestamp = [[[_session userOptions] objectForKey:kXfireShowChatTimeStampsOption] boolValue];
	
	if (showTimestamp)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setFormatterBehavior:[NSDateFormatter defaultFormatterBehavior]];
		[dateFormatter setDateFormat:@"[hh:mm aa] "];
		NSString *now = [dateFormatter stringFromDate:[chatMessage objectForKey:@"timestamp"]];
		username = [now stringByAppendingString:username];
		[dateFormatter release];
	}
	
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	[[cell usernameLabel] setText:username];
	[cell setMessageText:message];
	[cell setDelegate:self];
	
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!self.chatRoom)
		return 44;
	
	NSDictionary *chatMessage = [_messages objectAtIndex:[indexPath row]];
	NSString *message = [chatMessage objectForKey:@"message"];
	
	if ([chatMessage objectForKey:@"system"])
	{
		return 20;
	}
	
	CGFloat screenWidth = [self.tableView frame].size.width;
	
	CGFloat height = [JSCoreTextView measureFrameHeightForText:message
													  fontName:[XBChatMessageCell fontName]
													  fontSize:[XBChatMessageCell fontSize]
											constrainedToWidth:(screenWidth - ([XBChatMessageCell paddingLeft] * 2))
													paddingTop:[XBChatMessageCell paddingTop]
												   paddingLeft:[XBChatMessageCell paddingLeft]];
	height += [XBChatMessageCell padding] + [XBChatMessageCell nameHeight];
	
	return height;
}

#pragma mark -
#pragma mark XBChatMessageCellDelegate

- (void)chatMessageCell:(XBChatMessageCell *)chatMessageCell didSelectLink:(AHMarkedHyperlink *)link
{
	XBWebViewController *webViewController = [[[XBWebViewController alloc] initWithNibName:@"XBWebViewController"
																					bundle:nil
																					   url:[link URL]] autorelease];
	[self.navigationController pushViewController:webViewController animated:YES];
}


@end
