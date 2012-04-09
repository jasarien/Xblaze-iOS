//
//  XBPushPurchaseViewController.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 08/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import "XBPushPurchaseInfoViewController.h"

@interface XBPushPurchaseInfoViewController ()

@end

@implementation XBPushPurchaseInfoViewController

@synthesize scrollView = _scrollView;
@synthesize contentView = _contentView;

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
	
	self.title = @"Information";
	
	[self.scrollView setContentSize:[self.contentView frame].size];
	[self.scrollView addSubview:self.contentView];
}

- (void)viewDidUnload
{
	self.scrollView = nil;
	self.contentView = nil;
	[super viewDidUnload];
}

- (void)dealloc
{
	self.scrollView = nil;
	self.contentView = nil;
	[super dealloc];
}
@end
