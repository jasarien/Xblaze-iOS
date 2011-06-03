    //
//  XBDetailViewController.m
//  Xblaze-iPhone
//
//  Created by James on 16/05/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBDetailViewController.h"


@implementation XBDetailViewController

@synthesize popoverController;
@synthesize chatViewController = _chatViewController;

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	self.chatViewController = nil;
}

- (void)dealloc
{
	[super dealloc];
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
	[[(UINavigationController *)aViewController navigationBar] setBarStyle:UIBarStyleBlack];
	
	[self.navigationItem setLeftBarButtonItem:nil animated:YES];
	self.popoverController = nil;
}

- (void)setChatViewController:(XBChatViewController *)chatViewController
{
	[[_chatViewController view] removeFromSuperview];
	[_chatViewController release];
	_chatViewController = [chatViewController retain];
	
	
	//[self.navigationController setViewControllers:[NSArray arrayWithObjects:self, chatViewController, nil]];
}

@end
