//
//  FlatTableCellView.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 20/04/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

// to use: subclass FlatTableCellView and implement drawContentView

@interface FlatTableCellView : UITableViewCell {
	
	UIView *contentView;

}

- (void)drawContentView:(CGRect)rect; // subclasses should implement

@end

@interface FlatTableCellContentView : UIView
@end
