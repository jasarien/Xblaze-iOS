//
//  XBLazyImageView.m
//  Xblaze-iPhone
//
//  Created by James on 15/12/2011.
//  Copyright 2011 James Addyman. All rights reserved.
//

#import "XBLazyImageView.h"
#import "XBMediaCache.h"
#import <QuartzCore/QuartzCore.h>

@interface XBLazyImageView ()

- (void)commonInit;

@end

@implementation XBLazyImageView

@synthesize imageURL = _imageURL;
@synthesize showSpinner = _showSpinner;
@synthesize showBorder = _showBorder;
@synthesize isLoading = _isLoading;
@synthesize delegate = _delegate;
@synthesize placeholderImage = _placeholderImage;
@synthesize spinnerView = _spinner;

- (id)initWithFrame:(CGRect)frame imageURL:(NSURL *)imageURL
{
	if ((self = [self initWithFrame:frame]))
	{
		self.imageURL = imageURL;
		self.showSpinner = YES;
	}
				
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		[self commonInit];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[self commonInit];
}

- (void)commonInit
{
	self.backgroundColor = [UIColor whiteColor];
	self.layer.borderColor = [[UIColor blackColor] CGColor];
	self.layer.borderWidth = 1;
	self.opaque = YES;
	self.showSpinner = YES;
	self.showBorder = YES;
	_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[_spinner setHidesWhenStopped:YES];
	[self addSubview:_spinner];
	[_spinner setOrigin:CGPointMake(([self frame].size.width - [_spinner frame].size.width) / 2, ([self frame].size.height - [_spinner frame].size.height) / 2)];
}

- (void)dealloc
{
	[_imageData release], _imageData = nil;
	[_connection cancel];
	[_connection release], _connection = nil;
	
	self.placeholderImage = nil;
	self.imageURL = nil;
	[_spinner release], _spinner = nil;
	[super dealloc];
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	[_spinner setOrigin:CGPointMake(([self frame].size.width - [_spinner frame].size.width) / 2, ([self frame].size.height - [_spinner frame].size.height) / 2)];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	[_spinner setOrigin:CGPointMake(([self frame].size.width - [_spinner frame].size.width) / 2, ([self frame].size.height - [_spinner frame].size.height) / 2)];
}

- (void)setShowBorder:(BOOL)showBorder
{
	_showBorder = showBorder;
	
	if (_showBorder)
	{
		[self.layer setBorderWidth:1.0];
	}
	else
	{
		[self.layer setBorderWidth:0.0];
	}
}

- (void)setImageURL:(NSURL *)imageURL
{
	[_imageURL release];
	_imageURL = [imageURL retain];
}

- (void)setImage:(UIImage *)image
{
	[super setImage:image];
	
	_isLoading = NO;
	
	if ([self.delegate respondsToSelector:@selector(imageViewNewImageSet:)])
	{
		[self.delegate imageViewNewImageSet:self];
	}
	
	[self setClipsToBounds:YES];
}

- (void)startLoad
{
	if (_isLoading)
		return;
	
	if (self.showSpinner)
	{
		[self bringSubviewToFront:_spinner];
		[_spinner startAnimating];
	}
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		UIImage *anImage = [XBMediaCache imageForKey:[self.imageURL absoluteString]];
		
		if (!anImage)
		{
			anImage = [XBMediaCache imageForKey:[self.imageURL absoluteString]];
		}
		
		if (anImage)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[self setImage:anImage];
				[_spinner stopAnimating];
			});
			
			return;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.imageURL];
			[urlRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
			_connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
			_imageData = [[NSMutableData alloc] init];
			[_connection start];
			
			_isLoading = YES;
		});
	});
}

- (void)cancelLoad
{
	_isLoading = NO;
	[_connection cancel];
	[_spinner stopAnimating];
	[self setImage:self.placeholderImage];
	[_imageData release], _imageData = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	_isLoading = NO;
	[_spinner stopAnimating];
	[self setImage:self.placeholderImage];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_imageData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	_isLoading = NO;
	
	UIImage *anImage = [[UIImage alloc] initWithData:_imageData];
	[_imageData release], _imageData = nil;
	
	if (anImage)
	{
		[XBMediaCache writeImageToDisk:anImage withKey:[self.imageURL absoluteString]];
		[self setImage:anImage];
	}
	
	[anImage release], anImage = nil;
	[_spinner stopAnimating];
}

- (void)resetImageView
{
	[self cancelLoad];
	
	[_spinner stopAnimating];
	[_spinner removeFromSuperview];
	[_spinner release];
	_spinner = [[UIActivityIndicatorView alloc] init];
	[_spinner setHidesWhenStopped:YES];
	[self addSubview:_spinner];
	[_spinner setOrigin:CGPointMake(([self frame].size.width - [_spinner frame].size.width) / 2, ([self frame].size.height - [_spinner frame].size.height) / 2)];
}

@end
