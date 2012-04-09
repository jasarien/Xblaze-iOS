//
//  XBPushPurchaseViewController.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 08/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import "XBPushPurchaseViewController.h"
#import "XBPushPurchaseInfoViewController.h"
#import "MAConfirmButton.h"

@interface XBPushPurchaseViewController ()

@end

@implementation XBPushPurchaseViewController

@synthesize iconView = _iconView;
@synthesize titleLabel = _titleLabel;
@synthesize priceDetailLabel = _priceDetailLabel;
@synthesize descriptionLabel = _descriptionLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		
	}
	
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Upgrade";
	
	UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease];
	[self.navigationItem setLeftBarButtonItem:cancelButton];
	
	_purchaseButton = [[[MAConfirmButton alloc] initWithTitle:@"£0.69"
													  confirm:@"BUY NOW"] autorelease];
	[_purchaseButton setConfirmedTintColour:[UIColor orangeColor]];
	[_purchaseButton setToggleAnimation:MAConfirmButtonToggleAnimationRight];
	[_purchaseButton addTarget:self
						action:@selector(purchase:)
			  forControlEvents:UIControlEventTouchUpInside];
	[_purchaseButton setAnchor:CGPointMake(self.titleLabel.frame.origin.x + _purchaseButton.frame.size.width, self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 7)];
	[self.view addSubview:_purchaseButton];
}

- (void)viewDidUnload
{
	self.iconView = nil;
	self.titleLabel = nil;
	self.priceDetailLabel = nil;
	self.descriptionLabel = nil;
	
	[super viewDidUnload];
}

- (void)dealloc
{
	self.iconView = nil;
	self.titleLabel = nil;
	self.priceDetailLabel = nil;
	self.descriptionLabel = nil;
	
	[super dealloc];
}

- (IBAction)cancel:(id)sender
{
	[[self presentingViewController] dismissModalViewControllerAnimated:YES];
}

- (IBAction)moreInfo:(id)sender
{
	XBPushPurchaseInfoViewController *infoVC = [[[XBPushPurchaseInfoViewController alloc] initWithNibName:@"XBPushPurchaseInfoViewController" bundle:nil] autorelease];
	[self.navigationController pushViewController:infoVC animated:YES];
}

- (IBAction)restore:(id)sender
{
	
}

- (IBAction)purchase:(id)sender
{
	
}

@end
