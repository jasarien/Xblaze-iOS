//
//  XBScreenshotGamesListViewController.m
//  Xblaze-iPhone
//
//  Created by James on 21/04/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBScreenshotGamesListViewController.h"
#import "MFGameRegistry.h"
#import "XfireScreenshot.h"
#import "EGOThumbsViewController.h"
#import "EGOPhotoSource.h"
#import "EGOPhoto.h"

@implementation XBScreenshotGamesListViewController

@synthesize screenshots = _screenshots;

#pragma mark -
#pragma mark View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil screenshots:(NSDictionary *)screenshots
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		self.screenshots = screenshots;
		_sortedKeys = [[[self.screenshots allKeys] sortedArrayUsingSelector:@selector(compare:)] retain];
	}
	
	return self;
}

- (void)dealloc
{
	self.screenshots = nil;
	[_sortedKeys release], _sortedKeys = nil;
	[super dealloc];
}

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}



#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_sortedKeys count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ScreenshotGameCell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	NSString *key = [_sortedKeys objectAtIndex:indexPath.row];
	[[cell textLabel] setText:[MFGameRegistry longNameForGameID:[key intValue]]];
	[[cell imageView] setImage:[[MFGameRegistry registry] iconForGameID:[key intValue]]];
	
	NSString *subtitleText;
	
	if ([[self.screenshots objectForKey:key] count] > 1)
		subtitleText = [NSString stringWithFormat:@"%d screenshots", [[self.screenshots objectForKey:key] count]];
	else
		subtitleText = [NSString stringWithFormat:@"%d screenshot", [[self.screenshots objectForKey:key] count]];
	
	[[cell detailTextLabel] setText:subtitleText];
    
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *key = [_sortedKeys objectAtIndex:indexPath.row];
	NSArray *xfireScreenshots = [self.screenshots objectForKey:key];
	NSMutableArray *screenshots = [NSMutableArray array];
	for (XfireScreenshot *xfireScreenshot in xfireScreenshots)
	{
		EGOPhoto *screenshot = [[EGOPhoto alloc] initWithImageURL:[xfireScreenshot fullsizeURL]
														 thumbURL:[xfireScreenshot thumbnailURL]
															 name:[xfireScreenshot screenshotDescription]];
		[screenshots addObject:screenshot];
		[screenshot release];
	}
	
	EGOPhotoSource *photoSource = [[EGOPhotoSource alloc] initWithEGOPhotos:[[screenshots copy] autorelease]];
	EGOThumbsViewController *thumbsController = [[[EGOThumbsViewController alloc] initWithPhotoSource:photoSource] autorelease];
	[thumbsController setTitle:[MFGameRegistry longNameForGameID:[key intValue]]];
	[photoSource release];
														  
	[self.navigationController pushViewController:thumbsController animated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}





@end

