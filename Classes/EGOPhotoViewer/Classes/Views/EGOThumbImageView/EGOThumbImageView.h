//
//  EGOThumbImageView.h
//  EGOPhotoViewer
//
//  Created by Henrik Nyh on 2010-06-25.
//  Copyright 2010 Henrik Nyh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGOPhoto.h"
#import "EGOImageLoader.h"
#import "EGOThumbsViewController.h"

#define kThumbTagOffset 1000	// We need this since tag 0 is otherwise shared between thumb 0 and its superview

@interface EGOThumbImageView : UIControl <EGOImageLoaderObserver> {
	EGOPhoto *photo;
	UIImageView *imageView;
	UIActivityIndicatorView *activityView;
	EGOThumbsViewController *controller;
}

- (void)setPhoto:(EGOPhoto*)aPhoto;
- (void)addBorder;

@property(nonatomic,retain) EGOPhoto *photo;
@property(nonatomic,retain) UIImageView *imageView;
@property(nonatomic,assign) EGOThumbsViewController *controller;

@end
