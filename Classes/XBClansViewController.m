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

@implementation XBClansViewController

@synthesize xfSession = _xfSession;

- (id)initWithStyle:(UITableViewStyle)style
{
	if ((self = [super initWithStyle:style]))
	{
		
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	_xfSession = nil;
	[_clanListViewControllers release], _clanListViewControllers = nil;
	
	[super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];	
	[self setTitle:@"Communities"];	
}

- (void)xfSessionDidConnect
{	
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
	
	_clanListViewControllers = [[NSMutableArray alloc] init];
	
	NSArray *clanGroups = [[_xfSession friendGroupController] clans];
	if ([clanGroups count] > 0)
	{
		for (XfireFriendGroup *clan in clanGroups)
		{
			XBClanListViewController *clvc = [[[XBClanListViewController alloc] initWithNibName:@"XBClanListViewController" bundle:nil] autorelease];
			[[clvc view] setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
			[clvc setXfSession:_xfSession];
			[clvc setClanID:[clan groupID]];
			[clvc setClanName:[clan groupName]];
			[clvc setTitle:[clan groupName]];
			[_clanListViewControllers addObject:clvc];
		}
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

- (void)friendGroupWasAdded:(NSNotification *)note
{
	XfireFriendGroup *clan = [[note userInfo] objectForKey:@"group"];
	if ([clan groupType] == kXfireFriendGroupClan)
	{
		XBClanListViewController *clvc = [[[XBClanListViewController alloc] initWithNibName:@"XBClanListViewController" bundle:nil] autorelease];
		[clvc setXfSession:_xfSession];
		[clvc setClanID:[clan groupID]];
		[clvc setClanName:[clan groupName]];
		[clvc setTitle:[clan groupName]];
		[_clanListViewControllers addObject:clvc];
		[clvc view];
	}
	
	[self.tableView reloadData];
}

- (void)friendGroupWillBeRemoved:(NSNotification *)note
{
	XfireFriendGroup *clan = [[note userInfo] objectForKey:@"group"];
	if ([clan groupType] == kXfireFriendGroupClan)
	{
		for (XBClanListViewController *clanListViewController in _clanListViewControllers)
		{
			if ([clan groupID] == [clanListViewController clanID])
			{
				[_clanListViewControllers removeObject:clanListViewController];
			}
		}
	}
	
	[self.tableView reloadData];
}

- (void)friendGroupDidChange:(NSNotification *)note
{
	XfireFriendGroup *clan = [[note userInfo] objectForKey:@"group"];
	if ([clan groupType] == kXfireFriendGroupClan)
	{
		for (XBClanListViewController *clanListViewController in _clanListViewControllers)
		{
			if ([clan groupID] == [clanListViewController clanID])
			{
				[clanListViewController setClanName:[clan groupName]];
				[clanListViewController setTitle:[clan groupName]];
			}
		}
	}
	
	[self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_clanListViewControllers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	if (!cell)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ClanCell"] autorelease];
	}
	
	XBClanListViewController *clanListViewController = [_clanListViewControllers objectAtIndex:[indexPath row]];
	[[cell textLabel] setText:[clanListViewController clanName]];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.navigationController pushViewController:[_clanListViewControllers objectAtIndex:[indexPath row]] animated:YES];
}

@end
