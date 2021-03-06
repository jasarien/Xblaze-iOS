//
//  XBScrollableTabBar.m
//  ScrollableTabBar
//
//  Created by James Addyman on 20/10/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//
#import "XBScrollableTabBar.h"
#import "XBTabButton.h"

@interface XBScrollableTabBar ()

- (void)layoutTabs;
- (void)updateFaders;
- (void)tabSelected:(id)sender;

@end


@implementation XBScrollableTabBar

@synthesize style = _style;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame style:(XBScrollableTabBarStyle)style
{
    if ((self = [super initWithFrame:frame]))
	{
		_tabItems = [[NSMutableArray alloc] init];
		
		_background = [[UIImageView alloc] initWithFrame:frame];
		[_background setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[self addSubview:_background];
		
		_scrollView = [[UIScrollView alloc] initWithFrame:frame];
		[_scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[_scrollView setShowsHorizontalScrollIndicator:NO];
		[_scrollView setShowsVerticalScrollIndicator:NO];
		[_scrollView setDelegate:self];
		[self addSubview:_scrollView];
		
		_fadeLeft = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
		_fadeRight = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
		CGRect fadeFrame = [_fadeRight frame];
		fadeFrame.origin.x = self.frame.size.width - fadeFrame.size.width;
		[_fadeRight setFrame:fadeFrame];
		
		[self addSubview:_fadeLeft];
		[self addSubview:_fadeRight];
		
		self.style = style;
	}
	
    return self;
}

- (void)dealloc
{
	[_tabItems release], _tabItems = nil;
    [super dealloc];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect fadeFrame = [_fadeRight frame];
	fadeFrame.origin.x = self.frame.size.width - fadeFrame.size.width;
	[_fadeRight setFrame:fadeFrame];
	
	[self updateFaders];
}

- (void)setStyle:(XBScrollableTabBarStyle)style
{
	_style = style;
	
	NSString *imageBundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"images.bundle"];
	NSBundle *imageBundle = [NSBundle bundleWithPath:imageBundlePath];
	
	UIImage *backgroundImage = nil;
	UIImage *fadeLeft = nil;
	UIImage *fadeRight = nil;
	
	switch (self.style)
	{
		case XBScrollableTabBarStyleBlue:
			backgroundImage = [[UIImage imageWithContentsOfFile:[imageBundle pathForResource:@"barBackgroundBlue" ofType:@"png"]] stretchableImageWithLeftCapWidth:1
																																										   topCapHeight:0];
			fadeLeft = [UIImage imageWithContentsOfFile:[imageBundle pathForResource:@"fadeLeft_blue" ofType:@"png"]];
			fadeRight = [UIImage imageWithContentsOfFile:[imageBundle pathForResource:@"fadeRight_blue" ofType:@"png"]];
			break;
		case XBScrollableTabBarStyleBlack:
			backgroundImage = [[UIImage imageWithContentsOfFile:[imageBundle pathForResource:@"barBackgroundBlack" ofType:@"png"]] stretchableImageWithLeftCapWidth:1
																																											topCapHeight:0];
			fadeLeft = [UIImage imageWithContentsOfFile:[imageBundle pathForResource:@"fadeLeft_black" ofType:@"png"]];
			fadeRight = [UIImage imageWithContentsOfFile:[imageBundle pathForResource:@"fadeRight_black" ofType:@"png"]];
			break;
		case XBScrollableTabBarStyleTransparent:
			backgroundImage = [[UIImage imageWithContentsOfFile:[imageBundle pathForResource:@"barBackgroundTrans" ofType:@"png"]] stretchableImageWithLeftCapWidth:1
																																											topCapHeight:0];
			fadeLeft = [UIImage imageWithContentsOfFile:[imageBundle pathForResource:@"fadeLeft_trans" ofType:@"png"]];
			fadeRight = [UIImage imageWithContentsOfFile:[imageBundle pathForResource:@"fadeRight_trans" ofType:@"png"]];
			break;
		default:
			break;
	}
	
	[_background setImage:backgroundImage];
	[_fadeLeft setImage:fadeLeft];
	[_fadeRight setImage:fadeRight];
}

- (void)setTabItems:(NSArray *)tabItems
{
	[_tabItems release];
	_tabItems = [tabItems mutableCopy];
	
	[self layoutTabs];
}

- (NSArray *)tabItems
{
	return [[_tabItems copy] autorelease];
}

- (void)layoutTabs
{
	[[_scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	
	CGFloat currentXposition = 4.0;
	CGFloat padding = 4.0;
	
	CGFloat overallWidth = 0.0;
	
	for (XBTabItem *item in _tabItems)
	{
		XBTabButton *tabButton = [XBTabButton tabButtonWithTitle:[item title]];
		[tabButton setTag:[_tabItems indexOfObject:item]];
		[tabButton addTarget:self
					  action:@selector(tabSelected:)
			forControlEvents:UIControlEventTouchDown];
		
		CGRect frame = [tabButton frame];
		frame.origin.x = currentXposition;
		frame.origin.y = abs((self.frame.size.height - frame.size.height) / 2) + 1;
		[tabButton setFrame:frame];
		
		currentXposition = frame.origin.x + frame.size.width + padding;
		
		overallWidth += (frame.size.width + padding);
		
		[_scrollView addSubview:tabButton];
	}

	[_scrollView setContentSize:CGSizeMake((overallWidth + padding), self.frame.size.height)];
	[self selectTabAtIndex:0];
	[self updateFaders];
}

- (void)updateFaders
{
	[UIView beginAnimations:nil context:nil];
	
	if ([_scrollView contentOffset].x < ([_scrollView contentSize].width - self.frame.size.width))
		[_fadeRight setAlpha:1.0];
	else
		[_fadeRight setAlpha:0.0];
	
	if ([_scrollView contentOffset].x > 0)
		[_fadeLeft setAlpha:1.0];
	else
		[_fadeLeft setAlpha:0.0];
	
	[UIView commitAnimations];
}

- (void)tabSelected:(id)sender
{
	XBTabButton *tabButton = (XBTabButton *)sender;
	
	if ([tabButton isToggled])
		return;
	
	[tabButton setToggled:YES];
	
	[_previouslySelectedTabButton setToggled:NO];
	_previouslySelectedTabButton = tabButton;
	
	if ([self.delegate respondsToSelector:@selector(scrollableTabBar:didSelectTabAtIndex:)])
	{
		[self.delegate scrollableTabBar:self didSelectTabAtIndex:[tabButton tag]];
	}
}

- (void)selectTabAtIndex:(NSInteger)index
{
	if (index < 0 || index >= [[_scrollView subviews] count])
		return;
	
	XBTabButton *tabButton = [[_scrollView subviews] objectAtIndex:index];
	[self tabSelected:tabButton];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self updateFaders];
}

@end
