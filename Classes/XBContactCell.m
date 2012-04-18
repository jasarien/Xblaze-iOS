//
//  XBContactCell.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 18/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import "XBContactCell.h"
#import "XBLazyImageView.h"

@implementation XBContactCell

@synthesize iconView = _iconView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		self.iconView = [[[XBLazyImageView alloc] initWithFrame:CGRectMake(0, 0, 43, 43)] autorelease];
		[[self contentView] addSubview:self.iconView];
		[self.iconView setShowBorder:NO];
	}
	
	return self;
}

- (void)dealloc
{
	self.iconView = nil;
	[super dealloc];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	[self.textLabel setOriginX:51];
	[self.detailTextLabel setOriginX:51];
}

@end
