//
//  EGOPhoto.m
//  EGOPhotoViewer
//
//  Created by Devin Doty on 1/13/2010.
//  Copyright (c) 2008-2009 enormego
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGOPhoto.h"

@implementation EGOPhoto

@synthesize imageURL=_imageURL, thumbURL=_thumbURL, image=_image, thumb=_thumb, imageName=_imageName;

- (id)initWithImageURL:(NSURL*)aURL thumbURL:(NSURL*)aThumbURL name:(NSString*)aName {
	if ((self = [super init])) {
		_imageURL=[aURL retain];
		_thumbURL=[aThumbURL retain];
		_imageName=[aName retain];
	}
	
	return self;
}

- (id)initWithImageURL:(NSURL*)aURL name:(NSString*)aName{
	return [self initWithImageURL:aURL thumbURL:nil name:aName];
}

- (id)initWithImageURL:(NSURL*)aURL thumbURL:(NSURL*)aThumbURL{
	return [self initWithImageURL:aURL thumbURL:aThumbURL name:nil];
}

- (id)initWithImageURL:(NSURL*)aURL{
	return [self initWithImageURL:aURL thumbURL:nil name:nil];
}

- (BOOL)isEqual:(id)object{
	if ([object isKindOfClass:[EGOPhoto class]]) {
		if (((EGOPhoto*)object).imageURL == self.imageURL) {
			return YES;
		}
	}
	
	return NO;
}

- (NSURL *)thumbURL {
	return _thumbURL ? _thumbURL : _imageURL;
}

- (NSString*)imageDescription{
	return [NSString stringWithFormat:@"%@ , %@", [super description], self.imageURL];
}

- (void)dealloc{
	[_imageURL release]; _imageURL=nil;
	[_thumbURL release]; _thumbURL=nil;
	[_image release]; _image=nil;
	[_thumb release]; _thumb=nil;
	[_imageName release]; _imageName=nil;
	
	[super dealloc];
}

@end
