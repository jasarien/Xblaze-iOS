//
//  XBLazyImageView.h
//  Xblaze-iPhone
//
//  Created by James on 15/12/2011.
//  Copyright 2011 James Addyman. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XBLazyImageView;

@protocol XBLazyImageViewDelegate <NSObject>

- (void)imageViewNewImageSet:(XBLazyImageView *)imageView;

@end

@interface XBLazyImageView : UIImageView {

	NSURL *_imageURL;
	UIActivityIndicatorView *_spinner;
	NSURLConnection *_connection;
	NSMutableData *_imageData;
	
	BOOL _showSpinner;
	BOOL _showBorder;
	BOOL _isLoading;
	
	id <XBLazyImageViewDelegate> _delegate;
}

@property (nonatomic, retain) NSURL *imageURL;
@property (nonatomic, assign) BOOL showSpinner;
@property (nonatomic, assign) BOOL showBorder;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) id <XBLazyImageViewDelegate> delegate;
@property (nonatomic, readonly) UIActivityIndicatorView *spinnerView;
@property (nonatomic, retain) UIImage *placeholderImage;

- (id)initWithFrame:(CGRect)frame imageURL:(NSURL *)imageURL;
- (void)startLoad;
- (void)cancelLoad;
- (void)resetImageView;

@end
