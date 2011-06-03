//
//  EGOPhotoSource.m
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

#import "EGOPhotoSource.h"
#import "EGOImageLoader.h"
#import "EGOCache.h"
#import "EGOPhoto.h"

@implementation EGOPhotoSource

@synthesize photos=_photos;

- (id)initWithEGOPhotos:(NSArray*)thePhotos{
	if ((self = [super init])) {
		_photos = [thePhotos retain];
	}
	return self;
}

- (EGOPhoto*)photoAtIndex:(NSInteger)index{
	return [self.photos objectAtIndex:index];
}

- (NSInteger)count{
	return [self.photos count];
}

- (NSString*)description{
	return [NSString stringWithFormat:@"%@, %i Photos", [super description], [self.photos count], nil];
}

- (void)dealloc{
	[_photos release], _photos=nil;
	[super dealloc];
}


#pragma mark -
#pragma mark Customization
// Subclass and override these to customize.

- (UIColor *)navigationBarTintColor {
	return nil;
}

- (UIColor *)backgroundColor{
	return [UIColor blackColor];
}

- (UIColor *)thumbnailBackgroundColor{
	return [UIColor whiteColor];
}

- (NSInteger)thumbnailSize{
	return 75;
}

- (UIViewContentMode)thumbnailContentMode{
	return UIViewContentModeScaleAspectFill;
}

- (BOOL)thumbnailsHaveBorder{
	return YES;
}


@end
