//
//  EGOStoredBarStyles.h
//  EGOPhotoViewer
//
//  Created by Henrik Nyh on 2010-06-26.
//  Copyright 2010 Henrik Nyh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EGOStoredBarStyles : NSObject {
	UIStatusBarStyle statusBarStyle;
	UIBarStyle navBarStyle;
	BOOL navBarTranslucent;
	UIColor* navBarTintColor;	
	UIBarStyle toolBarStyle;
	BOOL toolBarTranslucent;
	UIColor* toolBarTintColor;	
	BOOL toolBarHidden;  
}

+ (id)storeFromController:(UIViewController *)controller;
- (void)restoreToController:(UIViewController *)controller withAnimation:(BOOL)isAnimated;

@property(nonatomic, assign) UIStatusBarStyle statusBarStyle;
@property(nonatomic, assign) UIBarStyle navBarStyle;
@property(nonatomic, assign) BOOL navBarTranslucent;
@property(nonatomic, retain) UIColor* navBarTintColor;	
@property(nonatomic, assign) UIBarStyle toolBarStyle;
@property(nonatomic, assign) BOOL toolBarTranslucent;
@property(nonatomic, retain) UIColor* toolBarTintColor;	
@property(nonatomic, assign) BOOL toolBarHidden;

@end
