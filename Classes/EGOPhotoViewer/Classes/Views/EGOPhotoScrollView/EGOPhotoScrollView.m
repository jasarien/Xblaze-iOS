//
//  EGOPhotoScrollView.m
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

#import "EGOPhotoScrollView.h"
#import "EGOPhotoImageView.h"

@implementation EGOPhotoScrollView

- (id)initWithFrame:(CGRect)frame {
		if ((self = [super initWithFrame:frame])) {
				// Initialization code
		
		self.backgroundColor = [UIColor redColor];
		self.scrollEnabled = YES;
		self.pagingEnabled = NO;
		self.clipsToBounds = NO;
		self.maximumZoomScale = 1.0f;  // Will be set from EGOPhotoImageView.
		self.minimumZoomScale = 1.0f;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		self.alwaysBounceVertical = NO;
		self.alwaysBounceHorizontal = NO;
		self.bouncesZoom = YES;
		self.bounces = YES;
		self.scrollsToTop = NO;
		self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		
		}
		return self;
}

- (void)zoomRectWithCenter:(CGPoint)center{

	if (self.zoomScale > 1.0f) {
		//	zoom out
		[((EGOPhotoImageView*)self.superview) killScrollViewZoom];
	} else {
		
		CGFloat zoomToScale = 1.85;
		CGFloat rectSide = MIN(self.contentSize.width, self.contentSize.height) / zoomToScale;
		
		//	zoom in
		CGFloat xCoor = center.x - rectSide / 2.0;
		CGFloat yCoor = center.y - rectSide / 2.0;
		
		if (xCoor < 0.0f) xCoor = 0.0f;
		if (yCoor < 0.0f) yCoor = 0.0f;
					
		[self zoomToRect:CGRectMake(xCoor, yCoor, rectSide, rectSide) animated:YES];
		
	}
}

- (void)toggleBars{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EGOPhotoViewToggleBars" object:nil];
}

#pragma mark -
#pragma mark Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[super touchesEnded:touches withEvent:event];
	UITouch *touch = [touches anyObject];
	
	if (touch.tapCount == 1) {
		//[self performSelector:@selector(toggleBars) withObject:nil afterDelay:0.2];
	} else if (touch.tapCount == 2) {
//		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(toggleBars) object:nil];
//		[self zoomRectWithCenter:[[touches anyObject] locationInView:self]];
	}
}

#pragma mark -
#pragma mark Disable/enabling zooming
// FIXME: There is a bug somewhere. Page to a failed image and you can't zoom. Page away then back and you can.

- (void)disableZooming {
	if (!storedMaxZoomScale) {  // Guard against setting to 1.0 if we disable twice.
		storedMaxZoomScale = self.maximumZoomScale;
	}
	self.maximumZoomScale = 1.0;
}

- (void)enableZooming {
	if (storedMaxZoomScale) {
		self.maximumZoomScale = storedMaxZoomScale;
	}
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
		[super dealloc];
}


@end
