//
//  FlatTableCellView.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 20/04/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import "FlatTableCellView.h"

#pragma mark FlatTableCellContentView implementation
#pragma mark -

@implementation FlatTableCellContentView

- (void)drawRect:(CGRect)rect
{
	[(FlatTableCellView *)[self superview] drawContentView:rect];
}

@end

#pragma mark FlatTableCellView implementation
#pragma mark -

@implementation FlatTableCellView

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		contentView = [[FlatTableCellContentView alloc] initWithStyle:UITableViewCellStyleDefault];
		contentView.opaque = YES;
		[self addSubview:contentView];
		[contentView release];
    }
    
	return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	CGRect bounds = [self bounds];
	//bounds.size.height -= 1; // leave room for the separator line
	[contentView setFrame:bounds];
}

- (void)setNeedsDisplay
{
	[super setNeedsDisplay];
	[contentView setNeedsDisplay];
}

- (void)drawContentView:(CGRect)rect
{
	NSAssert(FALSE, @"Developer error: override drawContentView in subclass");
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
