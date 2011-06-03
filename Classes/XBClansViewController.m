//
//  XBClansViewController.m
//  Xblaze-iPhone
//
//  Created by James on 24/01/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBClansViewController.h"
#import "XfireFriendGroupController.h"
#import "XfireFriendGroup_Private.h"
#import "XfireFriendGroup.h"
#import "XfireSession.h"
#import "XfireSession_Private.h"
#import "Xblaze_iPhoneAppDelegate.h"
#import "XBClanListViewController.h"
#import "XBTabItem.h"

NSString *kClansListControllerDidAppear = @"kClansListController";

@implementation XBClansViewController

@synthesize xfSession = _xfSession;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_currentClanViewController = nil;
	_previousClanViewController = nil;
	
	_xfSession = [(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] xfSession];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(friendGroupWasAdded:)
												 name:kXfireFriendGroupWasAddedNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(friendGroupWillBeRemoved:)
												 name:kXfireFriendGroupWillBeRemovedNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(friendGroupDidChange:)
												 name:kXfireFriendGroupDidChangeNotification
											   object:nil];
	
	_tabStrip = [[[XBScrollableTabBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44) style:XBScrollableTabBarStyleBlack] autorelease];
	[_tabStrip setDelegate:self];
	
	NSMutableArray *clanTabItems = [NSMutableArray array];
	_clanListViewControllers = [[NSMutableArray alloc] init];
	
	NSArray *clanGroups = [[_xfSession friendGroupController] clans];
	if ([clanGroups count] > 0)
	{
		for (XfireFriendGroup *clan in clanGroups)
		{
			[clanTabItems addObject:[[[XBTabItem alloc] initWithTitle:[clan groupName]] autorelease]];
			XBClanListViewController *clvc = [[[XBClanListViewController alloc] initWithNibName:@"XBClanListViewController" bundle:nil] autorelease];
			[[clvc view] setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
			[clvc setNavController:self.navigationController];
			[clvc setClanID:[clan groupID]];
			[_clanListViewControllers addObject:clvc];
			[clvc view];
		}
		
		[_tabStrip setTabItems:clanTabItems];
		_currentClanViewController = [_clanListViewControllers objectAtIndex:0];
	}
	
	[_tabStrip setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	[self.view addSubview:_tabStrip];
	CGRect frame = [[_currentClanViewController view] frame];
	frame.origin.y = [_tabStrip frame].size.height;
	[[_currentClanViewController view] setFrame:frame];
	[_currentClanViewController viewWillAppear:NO];
	[self.view addSubview:[_currentClanViewController view]];
	[_currentClanViewController viewDidAppear:NO];
	
	[self.navigationItem setTitle:@"Communities"];
}

- (void)xfSessionDidConnect
{
	_xfSession = [(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] xfSession];
	_tabStrip = [[[XBScrollableTabBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44) style:XBScrollableTabBarStyleBlack] autorelease];
	[_tabStrip setDelegate:self];
	
	NSMutableArray *clanTabItems = [NSMutableArray array];
	_clanListViewControllers = [[NSMutableArray alloc] init];
	
	NSArray *clanGroups = [[_xfSession friendGroupController] clans];
	if ([clanGroups count] > 0)
	{
		for (XfireFriendGroup *clan in clanGroups)
		{
			[clanTabItems addObject:[[[XBTabItem alloc] initWithTitle:[clan groupName]] autorelease]];
			XBClanListViewController *clvc = [[[XBClanListViewController alloc] initWithNibName:@"XBClanListViewController" bundle:nil] autorelease];
			[[clvc view] setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
			[clvc setNavController:self.navigationController];
			[clvc setClanID:[clan groupID]];
			[_clanListViewControllers addObject:clvc];
			[clvc view];
		}
		
		[_tabStrip setTabItems:clanTabItems];
		_currentClanViewController = [_clanListViewControllers objectAtIndex:0];
	}
	
	[_tabStrip setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	[self.view addSubview:_tabStrip];
	CGRect frame = [[_currentClanViewController view] frame];
	frame.origin.y = [_tabStrip frame].size.height;
	[[_currentClanViewController view] setFrame:frame];
	[_currentClanViewController viewWillAppear:NO];
	[self.view addSubview:[_currentClanViewController view]];
	[_currentClanViewController viewDidAppear:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[_currentClanViewController viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[_currentClanViewController viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] postNotificationName:kClansListControllerDidAppear
														object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[_currentClanViewController viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[_currentClanViewController viewDidDisappear:animated];
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
	_tabStrip = nil;
	[_clanListViewControllers release];
	_clanListViewControllers = nil;
}

- (void)dealloc
{
	_tabStrip = nil;
	_xfSession = nil;
	[_clanListViewControllers release];
	_clanListViewControllers = nil;
	
	[super dealloc];
}

- (void)scrollableTabBar:(XBScrollableTabBar *)tabBar didSelectTabAtIndex:(NSInteger)index
{
	_previousClanViewController = _currentClanViewController;
	
	_currentClanViewController = [_clanListViewControllers objectAtIndex:index];
	
	CGRect frame = [[_currentClanViewController view] frame];
	frame.origin.y = [_tabStrip frame].size.height;
	frame.size.width = self.view.frame.size.width;
	frame.size.height = self.view.frame.size.height - [_tabStrip frame].size.height;
	[[_currentClanViewController view] setFrame:frame];
	
	[[_currentClanViewController view] setAlpha:0];
	
	[_currentClanViewController viewWillAppear:YES];
	[self.view addSubview:[_currentClanViewController view]];
	[_currentClanViewController viewDidAppear:YES];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(removePreviousViewController)];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[[_currentClanViewController view] setAlpha:1.0];
	[UIView commitAnimations];
}

- (void)removePreviousViewController
{
	[_previousClanViewController viewWillDisappear:NO];
	[[_previousClanViewController view] removeFromSuperview];
	[_previousClanViewController viewDidDisappear:NO];
}

- (void)friendGroupWasAdded:(NSNotification *)note
{
	XfireFriendGroup *clan = [[note userInfo] objectForKey:@"group"];
	if ([clan groupType] == kXfireFriendGroupClan)
	{
		XBTabItem *tabItem = [[[XBTabItem alloc] initWithTitle:[clan groupName]] autorelease];
		NSMutableArray *tabItems = [NSMutableArray arrayWithArray:[_tabStrip tabItems]];
		[tabItems addObject:tabItem];
		[_tabStrip setTabItems:[[tabItems copy] autorelease]];
		XBClanListViewController *clvc = [[[XBClanListViewController alloc] initWithNibName:@"XBClanListViewController" bundle:nil] autorelease];
		[clvc setClanID:[clan groupID]];
		[_clanListViewControllers addObject:clvc];
		[clvc view];
		
		[_tabStrip selectTabAtIndex:0];
		
		_currentClanViewController = [_clanListViewControllers objectAtIndex:0];
		
		CGRect frame = [[_currentClanViewController view] frame];
		frame.origin.y = [_tabStrip frame].size.height;
		[[_currentClanViewController view] setFrame:frame];
		
		[[_currentClanViewController view] setAlpha:0];
		
		[_currentClanViewController viewWillAppear:YES];
		[self.view addSubview:[_currentClanViewController view]];
		[_currentClanViewController viewDidAppear:YES];
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(removePreviousViewController)];
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
		[[_currentClanViewController view] setAlpha:1.0];
		[UIView commitAnimations];		
	}
}

- (void)friendGroupWillBeRemoved:(NSNotification *)note
{
	XfireFriendGroup *clan = [[note userInfo] objectForKey:@"group"];
	if ([clan groupType] == kXfireFriendGroupClan)
	{
		NSMutableArray *tabItems = [[[_tabStrip tabItems] mutableCopy] autorelease];
		
		for (int i = 0; i < [tabItems count]; i++)
		{
			XBTabItem *tabItem = [tabItems objectAtIndex:i];
			XBClanListViewController *clanListController = [_clanListViewControllers objectAtIndex:i];
			if ([[tabItem title] isEqualToString:[clan groupName]])
			{
				[tabItems removeObject:tabItem];
				[[clanListController view] removeFromSuperview];
				[_clanListViewControllers removeObject:clanListController];
				
			}
		}
		
		_currentClanViewController = nil;
		[_tabStrip setTabItems:[[tabItems copy] autorelease]];
		[_tabStrip selectTabAtIndex:0];
	}
}

- (void)friendGroupDidChange:(NSNotification *)note
{
	XfireFriendGroup *clan = [[note userInfo] objectForKey:@"group"];
	if ([clan groupType] == kXfireFriendGroupClan)
	{
		for (XBClanListViewController *clvc in _clanListViewControllers)
		{
			if ([clan groupID] == [clvc clanID])
			{
				NSInteger index = [_clanListViewControllers indexOfObject:clvc];
				[[[_tabStrip tabItems] objectAtIndex:index] setTitle:[clan groupName]];
			}
		}
	}
}

@end
