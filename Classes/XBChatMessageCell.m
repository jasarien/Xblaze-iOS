//
//  XBChatMessageCell.m
//  Xblaze-iPhone
//
//  Created by James on 25/11/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import "XBChatMessageCell.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import "AHMarkedHyperlink.h"

@implementation XBChatMessageCell

@synthesize delegate = _delegate;

@synthesize usernameLabel = _usernameLabel;
@synthesize messageView = _messageView;

+ (CGFloat)paddingTop
{
	return 5.0f;
}

+ (CGFloat)paddingLeft
{
	return 5.0f;
}

+ (CGFloat)padding
{
	return 2.0f;
}

+ (NSString *)fontName
{
	return @"Helvetica";
}

+ (CGFloat)fontSize
{
	return 14.0f;
}

+ (CGFloat)nameHeight
{
	return 18.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{	
		CGRect usernameRect = CGRectMake([[self class] paddingLeft], [[self class] padding], (self.contentView.frame.size.width - ([[self class] paddingLeft] * 2)), [[self class] nameHeight]);
		
		_usernameLabel = [[[UILabel alloc] initWithFrame:usernameRect] autorelease];
		[_usernameLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[_usernameLabel setUserInteractionEnabled:YES];
		[_usernameLabel setFont:[UIFont boldSystemFontOfSize:[[self class] fontSize]]];
		[_usernameLabel setLineBreakMode:UILineBreakModeTailTruncation];
		[_usernameLabel setClipsToBounds:YES];

		_messageView = [[[JSCoreTextView alloc] initWithFrame:CGRectMake(0, usernameRect.origin.y + usernameRect.size.height, self.contentView.frame.size.width, 0)] autorelease];
		[_messageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[_messageView setTextAlignment:kCTLeftTextAlignment];
		[_messageView setFontName:[[self class] fontName]];
		[_messageView setFontSize:[[self class] fontSize]];
		[_messageView setLinkColor:[UIColor orangeColor]];
		[_messageView setHighlightedLinkColor:[UIColor whiteColor]];
		[_messageView setHighlightColor:[UIColor orangeColor]];
		[_messageView setPaddingTop:[[self class] paddingTop]];
		[_messageView setPaddingLeft:[[self class] paddingLeft]];
		[_messageView setDelegate:self];
		
		[[self contentView] addSubview:_usernameLabel];
		[[self contentView] addSubview:_messageView];
	}
	
	return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)setMessageText:(NSString *)messageText
{
	[_messageView setText:messageText];
	[self layoutSubviews];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect messageRect = [_messageView frame];
	messageRect.size.height = [JSCoreTextView measureFrameHeightForText:[_messageView text]
															   fontName:[[self class] fontName]
															   fontSize:[[self class] fontSize]
													 constrainedToWidth:([self.contentView frame].size.width - ([[self class] paddingLeft] * 2))
															 paddingTop:[[self class] paddingTop]
															paddingLeft:[[self class] paddingLeft]];
	[_messageView setFrame:messageRect];
	[_messageView setNeedsDisplay];
}

- (void)textView:(JSCoreTextView *)textView linkTapped:(AHMarkedHyperlink *)link
{
	if ([self.delegate respondsToSelector:@selector(chatMessageCell:didSelectLink:)])
	{
		[self.delegate chatMessageCell:self didSelectLink:link];
	}
}

@end
