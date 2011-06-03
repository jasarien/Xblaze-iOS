//
//  XBLoginViewController.m
//  Xblaze-iPhone
//
//  Created by James on 12/11/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import "XBLoginViewController.h"
#import "Xblaze_iPhoneAppDelegate.h"
#import "IFTemporaryModel.h"
#import "IFTextCellController.h"
#import "IFSwitchCellController.h"
#import "IFButtonCellController.h"
#import "XBWebViewController.h"
//#import "FlurryAPI.h"
#import <MessageUI/MessageUI.h>
#import "MBProgressHUD.h"

NSString *kUsernameKey = @"kUsernameKey";
NSString *kPasswordKey = @"kPasswordKey";
NSString *kRememberKey = @"kRememberKey";

@implementation XBLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		[self awakeFromNib];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	reach = [[Reachability reachabilityWithHostName:XfireHostName] retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showKeyboard:)
												 name:kShowKeyboardNotification
											   object:nil];
	self.model = [[IFTemporaryModel alloc] init];
	
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:kUsernameKey];
	NSString *password = nil;
	NSNumber *remember = [NSNumber numberWithBool:NO];
	
	if (username && [username length])
	{
		password = [self retrievePasswordForUsername:username];
		remember = [NSNumber numberWithBool:YES];
	}
	
	[self.model setObject:username forKey:kUsernameKey];
	[self.model setObject:password forKey:kPasswordKey];
	[self.model setObject:remember forKey:kRememberKey];
	[self.navigationItem setTitle:@"Xblaze"];	
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		[self.tableView setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];
	}
	else
	{
		[self.tableView setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg.jpg"]] autorelease]];
	}
	
	UIBarButtonItem *helpButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"help.png"]
																	style:UIBarButtonItemStyleBordered
																   target:self
																   action:@selector(help:)] autorelease];
	self.navigationItem.rightBarButtonItem = helpButton;
}

- (void)help:(id)sender
{
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	NSString *versionString = [info	valueForKey:(NSString *)kCFBundleVersionKey];
	
	if (_helpSheet)
		return;
		
	_helpSheet = [[[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Need help? (Version %@)", versionString]
															delegate:self
												   cancelButtonTitle:@"Cancel"
											  destructiveButtonTitle:nil
												   otherButtonTitles:@"About Xblaze", @"FAQ", @"Support", nil] autorelease];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[_helpSheet showFromBarButtonItem:(UIBarButtonItem *)sender animated:YES];
	}
	else
	{
		[_helpSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
		[_helpSheet showInView:self.view];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
	{ // About Xblaze
		NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
		
		NSString *aboutHTML = nil;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			aboutHTML = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"aboutiPad" ofType:@"html"]
												  encoding:NSUTF8StringEncoding
													 error:nil];
		}
		else
		{
			aboutHTML = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"]
												  encoding:NSUTF8StringEncoding
													 error:nil];
		}
		
		aboutHTML = [aboutHTML stringByReplacingOccurrencesOfString:@"%%VERSION%%" withString:[[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey]];
		XBWebViewController *aboutViewController = [[[XBWebViewController alloc] initWithNibName:@"XBWebViewController"
																						  bundle:nil
																					  htmlString:aboutHTML
																						 baseURL:baseURL] autorelease];
		[self.navigationController pushViewController:aboutViewController animated:YES];
	}
	else if (buttonIndex == 1)
	{
		XBWebViewController *faqViewController = [[[XBWebViewController alloc] initWithNibName:@"XBWebViewController"
																						bundle:nil
																						   url:[NSURL URLWithString:@"http://xblaze.co.uk/faq.html"]] autorelease];
		[self.navigationController pushViewController:faqViewController animated:YES];
	}
	else if (buttonIndex == 2)
	{ // Support
		if ([MFMailComposeViewController canSendMail])
		{
			NSMutableString *bodyString = [NSMutableString stringWithFormat:@"\n\n\n\nMy Details:\n\nDevice: %@\nOS Version: %@,\nXblaze Version: %@", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey]];
			
			[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
			MFMailComposeViewController *mailComposer = [[[MFMailComposeViewController alloc] init] autorelease];
			[mailComposer setToRecipients:[NSArray arrayWithObject:@"support@xblaze.co.uk"]];
			[mailComposer setSubject:@"Xblaze Support"];
			[mailComposer setMessageBody:bodyString isHTML:NO];
			[mailComposer setMailComposeDelegate:self];
			[self presentModalViewController:mailComposer animated:YES];
		}
		else
		{
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:support@xblaze.co.uk"]];
		}
	}
	
	_helpSheet = nil;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	[self dismissModalViewControllerAnimated:YES];
	
	switch (result)
	{
		case MFMailComposeResultSaved:
		{
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Message Saved"
															 message:@"Your message has been saved.\nYou may send it at a later date."
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] autorelease];
			[alert show];
		}
		case MFMailComposeResultFailed:
		{
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Sending Failed"
															 message:@"The message was unable to be sent.\nPlease try again."
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] autorelease];
			[alert show];
		}	
		case MFMailComposeResultCancelled:
		case MFMailComposeResultSent:
			break;
		default:
			break;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[self showKeyboard:nil];
	}
}

- (void)hideKeyboard
{
	IFTextCellController *usernameCell = [[tableGroups objectAtIndex:0] objectAtIndex:0];
	IFTextCellController *passwordCell = [[tableGroups objectAtIndex:0] objectAtIndex:1];
	
	[[usernameCell textField] resignFirstResponder];
	[[passwordCell textField] resignFirstResponder];	
}

- (void)showKeyboard:(NSNotification *)note
{
	[self hideConnectingOverlay];
	
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	IFTextCellController *usernameCell = [[tableGroups objectAtIndex:0] objectAtIndex:0];
	IFTextCellController *passwordCell = [[tableGroups objectAtIndex:0] objectAtIndex:1];
	
	@try
	{
		if ([[[passwordCell textField] text] length])
		{
			[[passwordCell textField] becomeFirstResponder];
		}
		else
		{
			[[usernameCell textField] becomeFirstResponder];
		}
	}
	@catch (NSException * e)
	{
		NSLog(@"Caught exception when making text field become first responder: %@", [e reason]);
	}
}

- (void)showConnectingOverlay
{
	_hud = [MBProgressHUD showHUDAddedTo:[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] window] animated:YES];
	[_hud setAnimationType:MBProgressHUDAnimationZoom];
	[_hud setLabelText:@"Connecting…"];
}

- (void)hideConnectingOverlay
{
	[MBProgressHUD hideHUDForView:[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] window] animated:YES];
	_hud = nil;
}

- (void)setOverlayMessage:(NSString *)message
{
	[_hud setLabelText:message];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (void)constructTableGroups
{	
	IFTextCellController *usernameCell = [[[IFTextCellController alloc] initWithLabel:@"Username" andPlaceholder:nil atKey:kUsernameKey inModel:self.model] autorelease];
	IFTextCellController *passwordCell = [[[IFTextCellController alloc] initWithLabel:@"Password" andPlaceholder:nil atKey:kPasswordKey inModel:self.model] autorelease];
	[[usernameCell textField] setReturnKeyType:UIReturnKeyNext];
	[[usernameCell textField] setKeyboardAppearance:UIKeyboardAppearanceAlert];
	[[usernameCell textField] setClearsOnBeginEditing:NO];
	[[usernameCell textField] setClearButtonMode:UITextFieldViewModeWhileEditing];
	[[usernameCell textField] setBackgroundColor:[UIColor clearColor]];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		CGRect textFrame = [[usernameCell textField] frame];
		textFrame.size.width = 275.0;
		[[usernameCell textField] setFrame:textFrame];
	}
	
	[usernameCell setShouldResignFirstResponderOnReturn:NO];
	[usernameCell setUpdateTarget:self];
	[usernameCell setUpdateAction:@selector(nextField)];
	[[passwordCell textField] setReturnKeyType:UIReturnKeyGo];
	[[passwordCell textField] setKeyboardAppearance:UIKeyboardAppearanceAlert];
	[[passwordCell textField] setClearsOnBeginEditing:NO];
	[[passwordCell textField] setClearButtonMode:UITextFieldViewModeWhileEditing];
	[[passwordCell textField] setBackgroundColor:[UIColor clearColor]];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		CGRect textFrame = [[passwordCell textField] frame];
		textFrame.size.width = 275.0;
		[[passwordCell textField] setFrame:textFrame];
	}
	[passwordCell setShouldResignFirstResponderOnReturn:NO];
	[passwordCell setUpdateTarget:self];
	[passwordCell setUpdateAction:@selector(connect)];
	[passwordCell setSecureTextEntry:YES];
	IFSwitchCellController *rememberCell = [[[IFSwitchCellController alloc] initWithLabel:@"Remember Password" atKey:kRememberKey inModel:self.model] autorelease];
	[rememberCell setUpdateTarget:self];
	[rememberCell setUpdateAction:@selector(toggleSaveCredentials)];
	IFButtonCellController *registerCell = [[[IFButtonCellController alloc] initWithLabel:@"Get An Xfire Account..." withAction:@selector(showRegisterPage) onTarget:self] autorelease];
	
	NSMutableArray *cells = [NSMutableArray arrayWithObjects:usernameCell, passwordCell, rememberCell, registerCell, nil];
	tableGroups = [[NSArray arrayWithObject:cells] retain];
}

- (void)showRegisterPage
{
	//[FlurryAPI logEvent:@"Get New Xfire Account"];
	
	NSURL *registerURL = [NSURL URLWithString:@"http://xfire.com/register"];
	XBWebViewController *registerController = [[[XBWebViewController alloc] initWithNibName:@"XBWebViewController" bundle:nil url:registerURL] autorelease];
	[[self navigationController] pushViewController:registerController animated:YES];
}

- (void)nextField
{
	IFTextCellController *passwordCell = [[tableGroups objectAtIndex:0] objectAtIndex:1];
	[[passwordCell textField] becomeFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	[self hideConnectingOverlay];
}

- (void)connect
{
	NSString *username, *password;
	username = [[self.model objectForKey:kUsernameKey] lowercaseString]; // Xfire enforces lowercase usernames on sign up, but doesn't use a case insensitive login...
	password = [self.model objectForKey:kPasswordKey];
	[username retain];
	[password retain];
	
	if ((!username || ![username length]) || (!password || ![password length]))
	{
		[username release], username = nil;
		[password release], password = nil;
		return; // don't try and login with a missing parameter
	}
	
	NSNumber *remember = [self.model objectForKey:kRememberKey];
	if ([remember boolValue])
	{
		[self saveUsername:username password:password];
	}
	
	[self showConnectingOverlay];

	
	IFTextCellController *passwordCell = [[tableGroups objectAtIndex:0] objectAtIndex:1];
	[[passwordCell textField] resignFirstResponder];
	
//	DebugLog(@"Checking reachability");
//	if ([reach currentReachabilityStatus] == NotReachable)
//	{
//		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't Connect"
//														message:@"Unable to contact the Xfire server, please check your internet connection and try again..."
//													   delegate:nil
//											  cancelButtonTitle:nil
//											  otherButtonTitles:@"OK", nil];
//		[alert show];
//		[alert release];
//		[[NSNotificationCenter defaultCenter] postNotificationName:kShowKeyboardNotification object:nil];
//		[self hideConnectingOverlay];
//		[username release], username = nil;
//		[password release], password = nil;
//		return;
//	}
	
	Xblaze_iPhoneAppDelegate *appDelegate = (Xblaze_iPhoneAppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate startNetworkIndicator];
	[appDelegate connectWithUsername:username password:password];
	
	[username release];
	[password release];
}

- (void)disconnect
{
	Xblaze_iPhoneAppDelegate *appDelegate = (Xblaze_iPhoneAppDelegate*)[[UIApplication sharedApplication] delegate];
	[appDelegate disconnect];
}

- (void)toggleSaveCredentials
{
	NSNumber *remember = [self.model objectForKey:kRememberKey];
	NSString *username, *password;
	username = [self.model objectForKey:kUsernameKey];
	password = [self.model objectForKey:kPasswordKey];
	[username retain];
	[password retain];
	[remember retain];
	
	if ([remember boolValue])
	{
		if ((username && [username length]) && (password && [password length]))
		{
			[self saveUsername:username password:password];
		}
	}
	else
	{
		[self deleteSavedLoginDetails];
	}
	
	[username release];
	[password release];
	[remember release];
}

- (void)saveUsername:(NSString *)usernameToSave password:(NSString *)passwordToSave
{
	[[NSUserDefaults standardUserDefaults] setObject:usernameToSave forKey:kUsernameKey];

#if !TARGET_IPHONE_SIMULATOR
	NSMutableDictionary *passwordEntry = [self newBaseDictionaryWithServer:XfireHostName account:usernameToSave];
	NSMutableDictionary *attributesToUpdate = [[NSMutableDictionary alloc] init];
	
	NSData *passwordData = [passwordToSave dataUsingEncoding:NSUTF8StringEncoding];
	[attributesToUpdate setObject:passwordData forKey:(id)kSecValueData];
	
	OSStatus status = SecItemUpdate((CFDictionaryRef)passwordEntry, (CFDictionaryRef)attributesToUpdate);
	
	[attributesToUpdate release];
	
	if (status == noErr) {
		[passwordEntry release];
		return;
	}
	
	SecItemDelete((CFDictionaryRef)passwordEntry);
	
	[passwordEntry setObject:passwordData forKey:(id)kSecValueData];
	
	SecItemAdd((CFDictionaryRef)passwordEntry, NULL);
	
	[passwordEntry release];
#else
	[[NSUserDefaults standardUserDefaults] setObject:passwordToSave forKey:kPasswordKey];
#endif
}

- (NSString *)retrievePasswordForUsername:(NSString *)savedUsername
{
#if !TARGET_IPHONE_SIMULATOR
	NSString *savedPassword = nil;
	
	NSMutableDictionary *passwordQuery = [self newBaseDictionaryWithServer:XfireHostName account:savedUsername];
	NSData *resultData = nil;
	
	[passwordQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
	[passwordQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	
	OSStatus status = SecItemCopyMatching((CFDictionaryRef)passwordQuery, (CFTypeRef *)&resultData);
	if (status == noErr && resultData)
		savedPassword = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
	
	[passwordQuery release];
	
	if (resultData)
	{
		[resultData release];
		resultData = nil;
	}
	
	return [savedPassword autorelease];
#else
	return [[NSUserDefaults standardUserDefaults] objectForKey:kPasswordKey];
#endif
}

- (void)deleteSavedLoginDetails
{
	[[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUsernameKey];
	
#if TARGET_IPHONE_SIMULATOR
	[[NSUserDefaults standardUserDefaults] setObject:nil forKey:kPasswordKey];
#endif
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (NSMutableDictionary *)newBaseDictionaryWithServer:(NSString *)server account:(NSString *)account 
{
	NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
	
	[query setObject:(id)kSecClassInternetPassword forKey:(id)kSecClass];
	[query setObject:server forKey:(id)kSecAttrServer];
	if (account) [query setObject:account forKey:(id)kSecAttrAccount];
	
	return query;
}

@end
