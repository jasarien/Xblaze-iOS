//
//  SearchFriendViewController.m
//  Xblaze-iPhone
//
//  Created by James on 10/12/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import "XBSearchFriendViewController.h"
#import "XfireFriend.h"
#import "XfireSession.h"
#import "XBAddFriendViewController.h"
#import "MBProgressHUD.h"

@implementation XBSearchFriendViewController

@synthesize searchBar = _searchBar, resultsTable = _resultsTable;
@synthesize searchResults;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(searchCompleted:)
													 name:kSearchCompleteNotification
												   object:nil];
    }
    
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self setTitle:@"Search for Friends"];
	app = (Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancel)] autorelease];
	[self.navigationItem setRightBarButtonItem:cancelButton];
	
	for (UIView *searchBarSubview in [_searchBar subviews]) {
		if ([searchBarSubview conformsToProtocol:@protocol(UITextInputTraits)]) {
			@try {
				[(UITextField *)searchBarSubview setKeyboardAppearance:UIKeyboardAppearanceAlert];
			}
			@catch (NSException * e) {
				// ignore exception
			}
		}
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[self.resultsTable setTableHeaderView:nil];
		[self.resultsTable setTableHeaderView:_searchBar];
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

- (void)viewDidUnload
{
	self.searchBar = nil;
	self.resultsTable = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		[self dismissModalViewControllerAnimated:NO];
}

- (void)dealloc
{
	self.searchResults = nil;
	
	self.searchBar = nil;
	self.resultsTable = nil;
	
    [super dealloc];
}

- (void)cancel
{
	[[self parentViewController] dismissModalViewControllerAnimated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[_searchBar resignFirstResponder];
	[app beginUserSearch:[_searchBar text]];
	[self showSearchingOverlay];
	_timeout = [[NSTimer scheduledTimerWithTimeInterval:10.0
												 target:self
											   selector:@selector(handleSearchTimeout:)
											   userInfo:nil
												repeats:NO] retain];
}

- (void)showSearchingOverlay
{
	_hud = [MBProgressHUD showHUDAddedTo:[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] window] animated:YES];
	[_hud setAnimationType:MBProgressHUDAnimationZoom];
	[_hud setLabelText:@"Searching…"];
}

- (void)handleSearchTimeout:(NSTimer *)timer
{	
	[self hideSearchingOverlay];
	
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Timed Out"
													 message:@"The search timed out.\nPlease try again..."
													delegate:nil
										   cancelButtonTitle:@"OK"
										   otherButtonTitles:nil] autorelease];
	[alert show];
}

- (void)hideSearchingOverlay
{	
	[MBProgressHUD hideHUDForView:[(Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate] window] animated:YES];
	_hud = nil;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[[self parentViewController] dismissModalViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	return [searchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *cellID = @"searchResultCell";
	
	UITableViewCell *cell = [_resultsTable dequeueReusableCellWithIdentifier:cellID];
	if (!cell)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID] autorelease];
	}
	
	XfireFriend *potentialFriend = [self.searchResults objectAtIndex:[indexPath row]];

	NSArray *friends = [[app xfSession] friends];
	BOOL friendAlreadyAdded = NO;
	
	for (XfireFriend *fr in friends)
	{
		if ([[potentialFriend userName] isEqualToString:[fr userName]])
		{
			if ([fr isDirectFriend])
			{
				friendAlreadyAdded = YES;
			}
			
			break;
		}
	}
	
	if (friendAlreadyAdded)
	{
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else
	{
		UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[addButton setFrame:CGRectMake(0, 0, 30, 30)];
		[addButton setBackgroundImage:[UIImage imageNamed:@"add.png"] forState:UIControlStateNormal];
		[addButton addTarget:self
					  action:@selector(addFriend:)
			forControlEvents:UIControlEventTouchUpInside];
		[addButton setTag:[indexPath row]];
		cell.accessoryView = addButton;
	}
	
	cell.textLabel.text = [potentialFriend userName];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", [potentialFriend firstName], [potentialFriend lastName]];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	return cell;
}

- (void)searchCompleted:(NSNotification *)note
{	
	if ([_timeout isValid])
	{
		[_timeout invalidate], [_timeout release], _timeout = nil;
	}
	
	self.searchResults = (NSArray *)[note object];
	[self.resultsTable reloadData];
	[self hideSearchingOverlay];
}

- (void)addFriend:(id)sender
{
	NSInteger index = [(UIButton *)sender tag];
	
	XfireFriend *friend = [self.searchResults objectAtIndex:index];
	XBAddFriendViewController *vc = [[[XBAddFriendViewController alloc] initWithNibName:@"XBAddFriendViewController" bundle:nil xfireFriend:friend] autorelease];
	
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
	[[navController navigationBar] setBarStyle:UIBarStyleBlack];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[navController setModalPresentationStyle:UIModalPresentationFormSheet];
		[navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
	}
	
	[self presentModalViewController:navController animated:YES];
}	

@end
