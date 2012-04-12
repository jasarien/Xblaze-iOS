//
//  XBSettingsViewController.m
//  Xblaze-iPhone
//
//  Created by James on 16/01/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBSettingsViewController.h"
#import "IFSwitchCellController.h"
#import "IFButtonCellController.h"
#import "IFTemporaryModel.h"
#import "XfireSession.h"
#import "Xblaze_iPhoneAppDelegate.h"
#import <MessageUI/MessageUI.h>
#import "XBWebViewController.h"

@implementation XBSettingsViewController

@synthesize xfSession;

- (void)dealloc
{
	[super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self setTitle:@"Settings"];
	
	[self.tableView setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg.jpg"]] autorelease]];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)] autorelease];
		[self.navigationItem setRightBarButtonItem:doneButton];
	}
	
	[self refreshSettings];
}

- (void)refreshSettings
{
	NSDictionary *currentOptions = [self.xfSession userOptions];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	
	if (!self.model)
	{
		self.model = [[IFTemporaryModel alloc] init];
	}
	
	[self.model setObject:[currentOptions objectForKey:kXfireShowFriendsOfFriendsOption] forKey:kXfireShowFriendsOfFriendsOption];
	[self.model setObject:[currentOptions objectForKey:kXfireShowMyOfflineFriendsOption] forKey:kXfireShowMyOfflineFriendsOption];
	[self.model setObject:[currentOptions objectForKey:kXfireShowNicknamesOption] forKey:kXfireShowNicknamesOption];
	[self.model setObject:[currentOptions objectForKey:kXfireShowChatTimeStampsOption] forKey:kXfireShowChatTimeStampsOption];
	[self.model setObject:[NSNumber numberWithBool:[defaults boolForKey:kAllowVibrateAlerts]] forKey:kAllowVibrateAlerts];
	[self.model setObject:[NSNumber numberWithBool:[defaults boolForKey:kAllowAudioAlerts]] forKey:kAllowAudioAlerts];
	
	[self constructTableGroups];
}

- (void)done
{
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)constructTableGroups
{	
	NSMutableArray *friendOptions = [NSMutableArray array];
	
	IFSwitchCellController *showNicknamesCell = [[[IFSwitchCellController alloc] initWithLabel:@"Display Nicknames" atKey:kXfireShowNicknamesOption inModel:self.model] autorelease];
	[showNicknamesCell setUpdateTarget:self];
	[showNicknamesCell setUpdateAction:@selector(updateSettings)];
	
	IFSwitchCellController *showMyFriendsOfFriendsCell = [[[IFSwitchCellController alloc] initWithLabel:@"Friends of Friends" atKey:kXfireShowFriendsOfFriendsOption inModel:self.model] autorelease];
	[showMyFriendsOfFriendsCell setUpdateTarget:self];
	[showMyFriendsOfFriendsCell setUpdateAction:@selector(updateSettings)];
	
	IFSwitchCellController *showOfflineFriendsCell = [[[IFSwitchCellController alloc] initWithLabel:@"Offline Friends" atKey:kXfireShowMyOfflineFriendsOption inModel:self.model] autorelease];
	[showOfflineFriendsCell setUpdateTarget:self];
	[showOfflineFriendsCell setUpdateAction:@selector(updateSettings)];
	
	[friendOptions addObject:showNicknamesCell];
	[friendOptions addObject:showOfflineFriendsCell];
	[friendOptions addObject:showMyFriendsOfFriendsCell];
	
	NSMutableArray *chatOptions = [NSMutableArray array];
	
	IFSwitchCellController *allowAudioCell = [[[IFSwitchCellController alloc] initWithLabel:@"New Message Sounds" atKey:kAllowAudioAlerts inModel:self.model] autorelease];
	[allowAudioCell setUpdateTarget:self];
	[allowAudioCell setUpdateAction:@selector(updateSoundSettings)];
	
	IFSwitchCellController *allowVibrateCell = [[[IFSwitchCellController alloc] initWithLabel:@"Vibration Alerts" atKey:kAllowVibrateAlerts inModel:self.model] autorelease];
	[allowVibrateCell setUpdateTarget:self];
	[allowVibrateCell setUpdateAction:@selector(updateAlertSettings)];
	
	IFSwitchCellController *showChatTimestampsCell = [[[IFSwitchCellController alloc] initWithLabel:@"Timestamps in Chats" atKey:kXfireShowChatTimeStampsOption inModel:self.model] autorelease];
	[showChatTimestampsCell setUpdateTarget:self];
	[showChatTimestampsCell setUpdateAction:@selector(updateSettings)];
	
	[chatOptions addObject:allowAudioCell];
	[chatOptions addObject:allowVibrateCell];
	[chatOptions addObject:showChatTimestampsCell];
	
	NSMutableArray *aboutSection = [NSMutableArray array];
	IFButtonCellController *aboutButtonCell = [[[IFButtonCellController alloc] initWithLabel:@"About Xblaze" withAction:@selector(showAboutView) onTarget:self] autorelease];
	IFButtonCellController *faqButtonCell = [[[IFButtonCellController alloc] initWithLabel:@"FAQ" withAction:@selector(showFAQ) onTarget:self] autorelease];
	IFButtonCellController *supportButtonCell = [[[IFButtonCellController alloc] initWithLabel:@"Support" withAction:@selector(showSupport) onTarget:self] autorelease];
	
	[aboutSection addObject:aboutButtonCell];
	[aboutSection addObject:faqButtonCell];
	[aboutSection addObject:supportButtonCell];
	
	tableGroups = [[NSArray arrayWithObjects:friendOptions, chatOptions, aboutSection, nil] retain];
	//tableHeaders = [[NSArray arrayWithObjects:@"", @"", @"" nil] retain];
}

- (void)updateSettings
{
	[xfSession setUserOptions:[self.model dictionary]];
}

- (void)updateSoundSettings
{
	[[NSUserDefaults standardUserDefaults] setBool:[[self.model objectForKey:kAllowAudioAlerts] boolValue]
											forKey:kAllowAudioAlerts];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateAlertSettings
{
	[[NSUserDefaults standardUserDefaults] setBool:[[self.model objectForKey:kAllowVibrateAlerts] boolValue]
											forKey:kAllowVibrateAlerts];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)showAboutView
{
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

- (void)showFAQ
{
	XBWebViewController *faqViewController = [[[XBWebViewController alloc] initWithNibName:@"XBWebViewController"
																					bundle:nil
																					   url:[NSURL URLWithString:@"http://xblaze.co.uk/faq.html"]] autorelease];
	[self.navigationController pushViewController:faqViewController animated:YES];
}

- (void)showSupport
{
	if ([MFMailComposeViewController canSendMail])
	{
		NSString *bodyString = [NSString stringWithFormat:@"\n\n\n\nMy Details:\n\nDevice: %@\nOS Version: %@,\nXblaze Version: %@", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey]];
		
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

@end