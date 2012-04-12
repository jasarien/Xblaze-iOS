//
//  XBChatViewController.m
//  Xblaze-iPhone
//
//  Created by James on 24/11/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import "XBChatViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "XBWebViewController.h"
#import "XfireFriend.h"
#import "MFGameRegistry.h"
#import "XBWebViewController.h"
#import "XBImageCache.h"
#import "Xblaze_iPhoneAppDelegate.h"
#import "XBScreenshotGamesListViewController.h"
#import "AutoHyperlinks.h"

#define profileImageURLString @"http://screenshot.xfire.com/avatar/%@.jpg?%d"

const CGFloat keyboardHeightPortrait = 216.0f;
const CGFloat keyboardHeightLandscape = 162.0f;
const CGFloat animationDuration = 0.2f;

@implementation XBChatViewController

@synthesize popoverController, openedFromClanList;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil chatController:(XBChatController *)controller
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		shouldUpdateUnreadCount = YES;
		chatController = [controller retain];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(messageReceived:)
													 name:kMessageReceivedNotification
												   object:chatController];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateFriendSummary:)
													 name:kXfireFriendDidChangeNotification
												   object:chatController];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateAvatar:)
													 name:kXfireFriendDidChangeNotification
												   object:chatController];	
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(animateBarUp:)
													 name:UIKeyboardWillShowNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(animateBarDown:)
													 name:UIKeyboardWillHideNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(textDidChange:)
													 name:UITextFieldTextDidChangeNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(typingNotificationReceieved:)
													 name:kTypingNotificationRecieved
												   object:[chatController chat]];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(screenshotsLoaded:)
													 name:kXfireFriendLoadedScreenshotsNotification
												   object:[[chatController chat] remoteFriend]];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleHidePopoverNotification:)
													 name:kHidePopoverNotification
												   object:nil];
		[self setHidesBottomBarWhenPushed:YES];
		
    }
	
    return self;
}

- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(messageReceived:)
												 name:kMessageReceivedNotification
											   object:chatController];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateFriendSummary:)
												 name:kXfireFriendDidChangeNotification
											   object:chatController];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateAvatar:)
												 name:kXfireFriendDidChangeNotification
											   object:chatController];	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(animateBarUp:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(animateBarDown:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textDidChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(typingNotificationReceieved:)
												 name:kTypingNotificationRecieved
											   object:[chatController chat]];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(screenshotsLoaded:)
												 name:kXfireFriendLoadedScreenshotsNotification
											   object:[[chatController chat] remoteFriend]];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleHidePopoverNotification:)
												 name:kHidePopoverNotification
											   object:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[chatController release];
	chatController = nil;
	
	if (profileImageData)
	{
		[profileImageData release];
		profileImageData = nil;
	}
	
	[toolbar release];
	[tableView release];
	[messageField release];
	[friendSummary release];
	[typingIcon release];
	
	toolbar = nil;
	tableView = nil;
	messageField = nil;
	friendSummary = nil;
	typingIcon = nil;
	
	[super dealloc];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillEnterBackgroundNotification:)
												 name:UIApplicationDidEnterBackgroundNotification
											   object:nil];
	
	[chatController setUnreadCount:0];
	[[NSNotificationCenter defaultCenter] postNotificationName:kResetUnreadCountNotification object:chatController];
	
	xfSession = [(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] xfSession];
	
	friendSummary = [[XBFriendSummaryViewController alloc] initWithNibName:@"XBFriendSummaryViewController" bundle:nil];
	[friendSummary setDelegate:self];
	[tableView setTableHeaderView:[friendSummary view]];
	[[friendSummary spinner] startAnimating];
	[self updateAvatar:nil];
	[self updateFriendSummary:nil];
	[self scrollTableToBottomAnimated:NO];
	
	_optionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"19-gear.png"]
													  style:UIBarButtonItemStyleBordered
													 target:self
													 action:@selector(options:)];
	NSDictionary *screenshots = [[[chatController chat] remoteFriend] screenshots];
	if (screenshots)
	{
		_screenShotsLoaded = YES;
	}
	else
	{
		_screenShotsLoaded = NO;
	}
	
	[self.navigationItem setRightBarButtonItem:_optionsButton];
	
	if (chatController)
	{
		[_optionsButton setEnabled:YES];
	}
	else
	{
		[_optionsButton setEnabled:NO];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if (chatController)
		[messageField becomeFirstResponder];
	else
		[messageField setEnabled:NO];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		{
			self.navigationItem.leftBarButtonItem = nil;
		}
	}
}

- (void)viewWillAppear:(BOOL)animated
{	
	[super viewWillAppear:animated];
	[tableView setDelegate:self];
	[self updateFriendSummary:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[tableView setDelegate:nil];
	
	if (shouldUpdateUnreadCount)
	{
		[chatController setUnreadCount:0];
		[[NSNotificationCenter defaultCenter] postNotificationName:kResetUnreadCountNotification object:chatController];
	}
}

- (void)handleWillEnterBackgroundNotification:(NSNotification *)note
{
	if (self.openedFromClanList == NO)
	{
		[[NSUserDefaults standardUserDefaults] setObject:[[[self.chatController chat] remoteFriend] userName] forKey:@"lastActiveChatUsername"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	[self.navigationController popToRootViewControllerAnimated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
	[toolbar release];
	[tableView release];
	[messageField release];
	[friendSummary release];
	[typingIcon release];
	
	toolbar = nil;
	tableView = nil;
	messageField = nil;
	friendSummary = nil;
	typingIcon = nil;
}

- (void)setChatController:(XBChatController *)aChatController
{
	xfSession = [(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] xfSession];
	
	[self.navigationController popToRootViewControllerAnimated:YES];
	
	[chatController release];
	chatController = [aChatController retain];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(animateBarUp:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(animateBarDown:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
	
	if (chatController)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(messageReceived:)
													 name:kMessageReceivedNotification
												   object:chatController];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateFriendSummary:)
													 name:kXfireFriendDidChangeNotification
												   object:chatController];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateAvatar:)
													 name:kXfireFriendDidChangeNotification
												   object:chatController];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(textDidChange:)
													 name:UITextFieldTextDidChangeNotification
												   object:messageField];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(typingNotificationReceieved:)
													 name:kTypingNotificationRecieved
												   object:[chatController chat]];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(screenshotsLoaded:)
													 name:kXfireFriendLoadedScreenshotsNotification
												   object:[[chatController chat] remoteFriend]];
		[[NSNotificationCenter defaultCenter] addObserver:tableView
												 selector:@selector(reloadData)
													 name:kXfireUserOptionsDidChangeNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleHidePopoverNotification:)
													 name:kHidePopoverNotification
												   object:nil];
		
		[self setTitle:[[[chatController chat] remoteFriend] displayName]];
		[tableView reloadData];
		[self updateFriendSummary:nil];
		[self updateAvatar:nil];
		[self scrollTableToBottomAnimated:YES];
		[_optionsButton setEnabled:YES];
		[chatController setUnreadCount:0];
		[[NSNotificationCenter defaultCenter] postNotificationName:kResetUnreadCountNotification object:chatController];
		
		[typingIcon setHidden:![chatController isTyping]];
		
		[self.popoverController dismissPopoverAnimated:YES];
	}
	else
	{
		self.title = @"";
		[messageField resignFirstResponder];
		[messageField setEnabled:NO];
		[self updateFriendSummary:nil];
		[_optionsButton setEnabled:NO];
		[tableView reloadData];
	}
}

- (XBChatController *)chatController
{
	return chatController;
}

- (void)handleHidePopoverNotification:(NSNotification *)note
{
	[messageField resignFirstResponder];
	[self.popoverController dismissPopoverAnimated:YES];
}

- (void)options:(id)sender
{
	if (_optionsSheet)
	{
		return;
	}
	
	_optionsSheet = [[[UIActionSheet alloc] initWithTitle:@"Options"
												 delegate:self
										cancelButtonTitle:nil
								   destructiveButtonTitle:@"Clear chat history"
										otherButtonTitles:nil] autorelease];
	[_optionsSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
	BOOL addedScreensButton = NO;
	if (_screenShotsLoaded)
	{
		[_optionsSheet addButtonWithTitle:@"Screenshots"];
		addedScreensButton = YES;
	}
	
	[_optionsSheet addButtonWithTitle:@"Cancel"];
	if (addedScreensButton)
	{
		[_optionsSheet setCancelButtonIndex:2];
	}
	else {
		[_optionsSheet setCancelButtonIndex:1];
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[_optionsSheet showFromBarButtonItem:_optionsButton animated:YES];
	}
	else {
		[_optionsSheet showInView:self.view];
	}
}

- (void)clearChatHistory
{
	[self.chatController clearChatHistory];
	[tableView reloadData];
}

- (void)showScreenshots
{
	[messageField resignFirstResponder];
	
	XfireFriend *friend = [[chatController chat] remoteFriend];
	
	if (friend)
	{		
		XBScreenshotGamesListViewController *screenshotsViewController = [[[XBScreenshotGamesListViewController alloc] initWithNibName:@"XBScreenshotGamesListViewController"
																																bundle:nil
																														   screenshots:[friend screenshots]] autorelease];
		[screenshotsViewController setTitle:[NSString stringWithFormat:@"%@'s screenshots", [friend displayName]]];
		[self.navigationController pushViewController:screenshotsViewController animated:YES];
	}
}

- (void)screenshotsLoaded:(NSNotification *)note
{
	_screenShotsLoaded = YES;
}

- (void)updateFriendSummary:(NSNotification *)note
{
	if (!chatController)
	{
		[[friendSummary displayNameLabel] setText:@""];
		[[friendSummary statusLabel] setText:@""];
		[[friendSummary gameInfoLabel] setText:@""];
		[[friendSummary gameIcon] setImage:nil];
		[[friendSummary userImageIcon] setImage:nil];
		[[friendSummary spinner] stopAnimating];
		[[friendSummary profileButton] setEnabled:NO];
		return;
	}
	
	XfireFriendChangeAttribute attr = [[[note userInfo] valueForKey:@"attribute"] intValue];
	XfireFriend *friend = [[chatController chat] remoteFriend];
	
	[[friendSummary profileButton] setEnabled:YES];
	
	if (attr == kXfireFriendWasRemoved)
	{
		[[friendSummary statusLabel] setText:@"Offline"];
		if ([messageField isFirstResponder])
		{
			[messageField resignFirstResponder];
		}
		
		[messageField setEnabled:NO];
		shouldUpdateUnreadCount = NO;
		return;
	}
	
	[[friendSummary displayNameLabel] setText:[friend displayName]];
	
	if (![[friend statusString] length])
		[[friendSummary statusLabel] setText:@"Online"];
	else
		[[friendSummary statusLabel] setText:[friend statusString]];
	
	if ([friend gameID])
	{
		NSDictionary *gameInfo = [MFGameRegistry infoForGameID:[friend gameID]];
		if (gameInfo)
		{
			[[friendSummary gameInfoLabel] setText:[NSString stringWithFormat:@"Playing %@", [gameInfo valueForKey:kMFGameRegistryLongNameKey]]];
			[[friendSummary gameIcon] setImage:[[MFGameRegistry registry] iconForGameID:[friend gameID]]];
		}
		else
		{
			[[friendSummary gameInfoLabel] setText:@"Playing Unknown Game..."];
			[[friendSummary gameIcon] setImage:[[MFGameRegistry registry] defaultImage]];
		}
	}
	else
	{
		[[friendSummary gameInfoLabel] setText:@"Not playing"];
		[[friendSummary gameIcon] setImage:[UIImage imageNamed:@"XfireSmall.png"]];
	}
	
	if (![friend isOnline])
	{
		[[friendSummary statusLabel] setText:@"Offline"];
		if ([messageField isFirstResponder])
		{
			[messageField resignFirstResponder];
		}
		
		[messageField setEnabled:NO];
		NSString *displayName = [[[chatController chat] remoteFriend] displayName];
		[messageField setPlaceholder:[NSString stringWithFormat:@"%@ is offline. %@ needs to be online to be able to send messages.", displayName, displayName]];
	}
	else
	{
		[messageField setEnabled:YES];
		[messageField setPlaceholder:nil];
		[messageField becomeFirstResponder];
	}
}

- (void)updateAvatar:(NSNotification *)note
{
	XfireFriendChangeAttribute attr = [[[note userInfo] objectForKey:@"attribute"] intValue];
	XfireFriend *friend = [[chatController chat] remoteFriend];
	
	if (note)
	{
		if (attr != kXfireFriendAvatarInfoPacketDidArrive)
		{
			return;
		}
	}
	
	UIImage *profileImage = [XBImageCache readImageFromCacheForKey:[[friend avatarURL] absoluteString]];
	if (profileImage)
	{
		[[friendSummary userImageIcon] setImage:profileImage];
		[[friendSummary spinner] stopAnimating];
	}
	else if ([friend avatarURL])
	{
		NSURLRequest *request = [NSURLRequest requestWithURL:[friend avatarURL]];
		[NSURLConnection connectionWithRequest:request delegate:self];
		[[friendSummary spinner] startAnimating];
	}
}

- (void)scrollTableToBottomAnimated:(BOOL)animated
{
	if ([[chatController chatMessages] count] > 1)
	{
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([[chatController chatMessages] count] - 1) inSection:0];
		[tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
	}
}

- (IBAction)hideKeyboard
{
	[messageField resignFirstResponder];
}

- (void)animateBarUp:(NSNotification *)note
{	
	CGRect keyboardBounds;
	[[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
	
	keyboardBounds = [self.view convertRect:keyboardBounds fromView:[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] window]];
		
	CGRect toolbarRect = toolbar.frame;
	CGRect tableRect = [tableView frame];
	
	toolbarRect.origin.y = keyboardBounds.origin.y - toolbarRect.size.height;
	tableRect.size.height = toolbarRect.origin.y;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[toolbar setFrame:toolbarRect];
	[tableView setFrame:tableRect];
	[UIView commitAnimations];
	
	[self scrollTableToBottomAnimated:NO];
}

- (void)animateBarDown:(NSNotification *)note
{	
	CGRect keyboardBounds;
	[[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
	
	keyboardBounds = [self.view convertRect:keyboardBounds fromView:[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] window]];
	
	CGRect toolbarRect = toolbar.frame;
	CGRect tableRect = [tableView frame];
	
	toolbarRect.origin.y = keyboardBounds.origin.y - toolbarRect.size.height;
	tableRect.size.height = toolbarRect.origin.y;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[toolbar setFrame:toolbarRect];
	[tableView setFrame:tableRect];
	[UIView commitAnimations];
}

- (void)messageReceived:(NSNotification *)note
{
	[tableView reloadData];
	[self scrollTableToBottomAnimated:YES];
	[typingIcon setHidden:YES];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[chatController setUnreadCount:0];
		[[NSNotificationCenter defaultCenter] postNotificationName:kResetUnreadCountNotification object:chatController];
	}
}

- (void)chatMessageCell:(XBChatMessageCell *)chatMessageCell didSelectLink:(AHMarkedHyperlink *)link
{
	XBWebViewController *webViewController = [[[XBWebViewController alloc] initWithNibName:@"XBWebViewController"
																					bundle:nil
																					   url:[link URL]] autorelease];
	[self.navigationController pushViewController:webViewController animated:YES];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	if (!chatController)
		return 7;
	
    return [[chatController chatMessages] count];
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!chatController)
		return 44;
	
	NSDictionary *chatMessage = [[chatController chatMessages] objectAtIndex:[indexPath row]];
	NSString *message = [chatMessage objectForKey:kChatMessageKey];
	
	CGFloat screenWidth = [tableView frame].size.width;
	
	CGFloat height = [JSCoreTextView measureFrameHeightForText:message
													  fontName:[XBChatMessageCell fontName]
													  fontSize:[XBChatMessageCell fontSize]
											constrainedToWidth:(screenWidth - ([XBChatMessageCell paddingLeft] * 2))
													paddingTop:[XBChatMessageCell paddingTop]
												   paddingLeft:[XBChatMessageCell paddingLeft]];
	height += [XBChatMessageCell padding] + [XBChatMessageCell nameHeight];
	
	return height;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	if (!chatController)
	{
		if (indexPath.row == 6)
		{
			static NSString *noActiveChatCellID = @"NoActiveChatCellID";
			UITableViewCell *noActiveChatCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:noActiveChatCellID] autorelease];
			[[noActiveChatCell textLabel] setText:@"No Active Chat..."];
			[[noActiveChatCell textLabel] setTextAlignment:UITextAlignmentCenter];
			[noActiveChatCell setSelectionStyle:UITableViewCellSelectionStyleNone];
			return noActiveChatCell;
		}
		else
		{
			static NSString *blankCellID = @"BlankCellID";
			UITableViewCell *blankCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:blankCellID] autorelease];
			[blankCell setSelectionStyle:UITableViewCellSelectionStyleNone];
			return blankCell;
		}
	}
	
    static NSString *CellIdentifier = @"XfireMessageCell";
    
    XBChatMessageCell *cell = (XBChatMessageCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[XBChatMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    	
	NSDictionary *chatMessage = [[chatController chatMessages] objectAtIndex:[indexPath row]];
	NSString *username = nil;
	if ([[chatMessage objectForKey:kChatIdentityKey] isEqualToString:[[xfSession loginIdentity] userName]])
	{
		username = [[xfSession loginIdentity] displayName];
	}
	else
	{
		username = [[xfSession friendForUserName:[chatMessage objectForKey:kChatIdentityKey]] displayName];
	}
	
	NSString *message = [chatMessage objectForKey:kChatMessageKey];
	
	BOOL showTimestamp = [[[xfSession userOptions] objectForKey:kXfireShowChatTimeStampsOption] boolValue];
	
	if (showTimestamp)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setFormatterBehavior:[NSDateFormatter defaultFormatterBehavior]];
		[dateFormatter setDateFormat:@"[hh:mm aa] "];
		NSString *now = [dateFormatter stringFromDate:[chatMessage objectForKey:kChatDateKey]];
		username = [now stringByAppendingString:username];
		[dateFormatter release];
	}
	
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	[[cell usernameLabel] setText:username];
	[cell setMessageText:message];
	[cell setDelegate:self];
	
    return cell;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (actionSheet == _optionsSheet)
	{
		if (buttonIndex == [actionSheet cancelButtonIndex])
		{
			_optionsSheet = nil;
			return;
		}
		else if (buttonIndex == [actionSheet destructiveButtonIndex])
		{
			[self clearChatHistory];
		}
		else
		{
			[self showScreenshots];
		}
		
		_optionsSheet = nil;
	}
	else
	{
		if (buttonIndex == [actionSheet cancelButtonIndex])
			return;
		
		NSURL *url = [_tempLinks objectAtIndex:buttonIndex];
		[_tempLinks release];
		_tempLinks = nil;
		
		XBWebViewController *webView = [[[XBWebViewController alloc] initWithNibName:@"XBWebViewController" bundle:nil url:url] autorelease];
		[self.navigationController pushViewController:webView animated:YES];
	}
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
	if (actionSheet == _optionsSheet)
	{
		_optionsSheet = nil;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSString *message = [messageField text];
	if (![message length])
	{	
		return NO;
	}
	
	[messageField setText:@""];
	[chatController sendMessage:message];
	[tableView reloadData];
	
	[self scrollTableToBottomAnimated:YES];
	
	return YES;
}

- (void)textDidChange:(NSNotification *)note
{
	[[chatController chat] sendTypingNotification];
}

- (void)handleLinkTouched:(NSNotification *)note
{
	[messageField resignFirstResponder];
	
	NSString *urlString = [note object];
	NSURL *url = [NSURL URLWithString:urlString];
	
	XBWebViewController *webView = [[[XBWebViewController alloc] initWithNibName:@"XBWebViewController" bundle:nil url:url] autorelease];
	[self.navigationController pushViewController:webView animated:YES];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (!profileImageData)
		profileImageData = [[NSMutableData alloc] init];
	
	[profileImageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[[friendSummary spinner] stopAnimating];
	
	UIImage *image = [UIImage imageWithData:profileImageData];
	if (image)
	{
		[[friendSummary userImageIcon] setImage:image];
		XfireFriend *friend = [[chatController chat] remoteFriend];
		[XBImageCache writeImage:image forKey:[[friend avatarURL] absoluteString]];
	}
	else
	{
		[[friendSummary userImageIcon] setImage:[UIImage imageNamed:@"defaultUserImage.png"]];
	}

	[profileImageData release];
	profileImageData = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[[friendSummary spinner] stopAnimating];
	
	if (![[friendSummary userImageIcon] image])
		[[friendSummary userImageIcon] setImage:[UIImage imageNamed:@"defaultUserImage.png"]];
	
	[profileImageData release];
	profileImageData = nil;
}

- (void)friendSummaryViewTapped:(XBFriendSummaryViewController *)summaryView
{
	[messageField resignFirstResponder];
	
	XfireFriend *friend = [[chatController chat] remoteFriend];
	
	NSString *profileURLString = [NSString stringWithFormat:@"http://xfire.com/profile/%@", [friend userName]];
	NSURL *profileURL = [NSURL URLWithString:profileURLString];
	
	XBWebViewController *profileWebView = [[[XBWebViewController alloc] initWithNibName:@"XBWebViewController" bundle:nil url:profileURL] autorelease];
	[self.navigationController pushViewController:profileWebView animated:YES];
}

- (void)typingNotificationReceieved:(NSNotification *)note
{
	BOOL isTyping = [[[note userInfo] objectForKey:@"typing"] boolValue];
	
	if (isTyping)
	{
		[typingIcon setHidden:NO];
	}
	else
	{
		[typingIcon setHidden:YES];
	}
}

#pragma mark -
#pragma mark Split view support

- (void)splitViewController:(UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
    barButtonItem.title = @"Friends";
	[self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
	self.popoverController = pc;
}

- (void)splitViewController:(UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{	
	[self.navigationItem setLeftBarButtonItem:nil animated:YES];
	self.popoverController = nil;
}

@end
