//
//  XBScrollableTabBar.h
//  ScrollableTabBar
//
//  Created by James Addyman on 20/10/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBTabItem.h"

@class XBScrollableTabBar, XBTabButton;

typedef enum {
	
	XBScrollableTabBarStyleBlack,
	XBScrollableTabBarStyleBlue,
	XBScrollableTabBarStyleTransparent
	
} XBScrollableTabBarStyle;

@protocol XBScrollableTabBarDelegate <NSObject>

- (void)scrollableTabBar:(XBScrollableTabBar *)tabBar didSelectTabAtIndex:(NSInteger)index;

@end

@interface XBScrollableTabBar : UIView <UIScrollViewDelegate> {

	UIScrollView *_scrollView;
	
	NSMutableArray *_tabItems;
	
	XBScrollableTabBarStyle _style;
	
	UIImageView *_background;
	UIImageView *_fadeLeft;
	UIImageView *_fadeRight;
	
	XBTabButton *_previouslySelectedTabButton;
	
	id <XBScrollableTabBarDelegate> _delegate;
}

@property (nonatomic, assign) XBScrollableTabBarStyle style;
@property (nonatomic, assign) id <XBScrollableTabBarDelegate> delegate;

- (id)initWithFrame:(CGRect)frame style:(XBScrollableTabBarStyle)style;
- (void)setTabItems:(NSArray *)tabItems;
- (NSArray *)tabItems;
- (void)selectTabAtIndex:(NSInteger)index;

@end
