//
//  XBFriendRequestTableViewCell.m
//  Xblaze-iPhone
//
//  Created by James on 20/06/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBFriendRequestTableViewCell.h"
#import "XfireFriend.h"

@implementation XBFriendRequestTableViewCell

@synthesize friend = _friend;
@synthesize delegate = _delegate;

+ (CGFloat)heightWithText:(NSString *)text
{
	CGFloat height = 6 + 22 + 2 + 7 + 35 + 5;	//clusterfuck
												//6 = padding
												//22 = text labelheight
												//2 = padding
												//7 = padding
												//35 = button height
												//5 = padding
	
	height += [text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(300, MAXFLOAT)].height;
	
	return height;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
		_declineButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[_declineButton setTitle:@"Decline" forState:UIControlStateNormal];
		[_declineButton addTarget:self
						   action:@selector(decline:)
				 forControlEvents:UIControlEventTouchUpInside];
		[_declineButton sizeToFit];
		[self addSubview:_declineButton];
		
		_acceptButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[_acceptButton setTitle:@"Accept" forState:UIControlStateNormal];
		[_acceptButton addTarget:self
						  action:@selector(accept:)
				forControlEvents:UIControlEventTouchUpInside];
		[_acceptButton sizeToFit];
		[self addSubview:_acceptButton];
	}
	
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)setFriend:(XfireFriend *)friend
{
	[_friend release];
	_friend = [friend retain];
	
	[[self textLabel] setText:[_friend displayName]];
	[[self detailTextLabel] setText:[_friend statusString]];
	[self.detailTextLabel setNumberOfLines:0];
	[self.detailTextLabel sizeToFit];
	
	[self setNeedsLayout];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect frame = [self.textLabel frame];
	frame.origin = CGPointMake(10, 6);
	[self.textLabel setFrame:frame];
	
	frame = [self.detailTextLabel frame];
	frame.origin.x = self.textLabel.frame.origin.x;
	frame.origin.y = self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 2;
	[self.detailTextLabel setFrame:frame];
	
	frame = [_acceptButton frame];
	frame.origin.x = [self.detailTextLabel frame].origin.x;
	frame.origin.y = [self.detailTextLabel frame].origin.y + [self.detailTextLabel frame].size.height + 7;
	[_acceptButton setFrame:frame];
	
	frame = [_declineButton frame];
	frame.origin.x = self.contentView.frame.size.width - frame.size.width - 10;
	frame.origin.y = [_acceptButton frame].origin.y;
	[_declineButton setFrame:frame];
}

- (void)decline:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(requestCell:didDeclineInvite:)])
	{
		[self.delegate requestCell:self didDeclineInvite:self.friend];
	}
}

- (void)accept:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(requestCell:didAcceptInvite:)])
	{
		[self.delegate requestCell:self didAcceptInvite:self.friend];
	}	
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
}

- (void)dealloc
{
	self.friend = nil;
	self.delegate = nil;
	[super dealloc];
}


@end
