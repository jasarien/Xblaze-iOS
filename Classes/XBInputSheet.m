//
//  JSInputSheet.m
//  JSInputSheet
//
//  Created by James on 07/11/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBInputSheet.h"
#import <QuartzCore/QuartzCore.h>

@interface XBInputSheet ()

- (void)done:(id)sender;
- (void)cancel:(id)sender;

- (void)showDimmingViewInView:(UIView *)view;
- (void)showInputViewInView:(UIView *)view;

- (void)hideDimmingView;

- (void)dismiss;
- (void)removeViews;

@end


@implementation XBInputSheet

@synthesize titleLabel = _titleLabel;
@synthesize textField = _textField;
@synthesize delegate = _delegate;

- (id)initWithTitle:(NSString *)title delegate:(id <XBInputSheetDelegate>)delegate
{
	if ((self = [super initWithFrame:CGRectMake(0, 0, 320, 100)]))
	{
		[self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		
		UIView *background = [[[UIView alloc] initWithFrame:[self frame]] autorelease];
		[background setBackgroundColor:[UIColor blackColor]];
		[background setAlpha:0.8];
		[background.layer setCornerRadius:5.0];
		[background.layer setShadowOffset:CGSizeMake(0, 4)];
		[background.layer setShadowOpacity:0.6];
		[background.layer setShouldRasterize:YES];
		[background setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
		[self addSubview:background];
		
		self.titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 14, 280, 21)] autorelease];
		[self.titleLabel setText:title];
		[self.titleLabel setTextColor:[UIColor whiteColor]];
		[self.titleLabel setFont:[UIFont boldSystemFontOfSize:17.0]];
		[self.titleLabel setShadowColor:[UIColor blackColor]];
		[self.titleLabel setShadowOffset:CGSizeMake(0, -1)];
		[self.titleLabel setTextAlignment:UITextAlignmentCenter];
		[self.titleLabel setBackgroundColor:[UIColor clearColor]];
		[self.titleLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[self.titleLabel setOpaque:NO];
		
		[self addSubview:self.titleLabel];
		
		self.textField = [[[UITextField alloc] initWithFrame:CGRectMake(20, 49, 280, 31)] autorelease];
		[self.textField setBorderStyle:UITextBorderStyleRoundedRect];
		[self.textField setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[self.textField setDelegate:self];
		[self.textField setKeyboardAppearance:UIKeyboardAppearanceAlert];
		[self.textField setReturnKeyType:UIReturnKeyDone];
		[self.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
		[self.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
		
		[self addSubview:self.textField];
				
		UIToolbar *toolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] autorelease];
		[toolbar setBarStyle:UIBarStyleBlack];
		[toolbar setTranslucent:YES];
		
		UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																					 target:self
																					 action:@selector(done:)] autorelease];
		UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																					   target:self
																					   action:@selector(cancel:)] autorelease];
		UIBarButtonItem *space = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																				target:nil action:nil] autorelease];
		[toolbar setItems:[NSArray arrayWithObjects:cancelButton, space, doneButton, nil]];
		
		[self.textField setInputAccessoryView:toolbar];
		
		self.delegate = delegate;
		
	}
	
	return self;
}

- (void)dealloc
{
	self.titleLabel = nil;
	self.textField = nil;
	self.delegate = nil;
	_dimmingView = nil;
	
	[super dealloc];
}

- (void)show
{
	[self showDimmingViewInView:[[UIApplication sharedApplication] keyWindow]];
	[self showInputViewInView:[[UIApplication sharedApplication] keyWindow]];
}

- (void)showInView:(UIView *)view
{
	[self showDimmingViewInView:view];
	[self showInputViewInView:view];
}

- (void)showDimmingViewInView:(UIView *)view
{
	_dimmingView = [[[UIView alloc] initWithFrame:[view frame]] autorelease];
	[_dimmingView setBackgroundColor:[UIColor blackColor]];
	[_dimmingView setAlpha:0.0];
	[_dimmingView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	[view addSubview:_dimmingView];
	
	[UIView beginAnimations:nil context:nil];
	
	[_dimmingView setAlpha:0.4];
	
	[UIView commitAnimations];
}

- (void)showInputViewInView:(UIView *)view
{
	CGFloat yPos = 0;
	
	CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
	if (CGRectIsEmpty(statusBarFrame))
	{
		yPos = -5;
	}
	else
	{
		yPos = 15;
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		yPos = -5;
	}
	
	CGRect aFrame = [self frame];
	aFrame.origin = CGPointMake(0, aFrame.origin.y - aFrame.size.height);
	aFrame.size.width = view.frame.size.width;
	[self setFrame:aFrame];
	[view addSubview:self];
	
	[UIView beginAnimations:nil context:nil];
	
	aFrame.origin.y = yPos;
	[self setFrame:aFrame];
	
	[UIView commitAnimations];
	
	[self.textField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ([self.delegate respondsToSelector:@selector(inputSheetDidDismiss:)])
	{
		[self.delegate inputSheetDidDismiss:self];
	}
	
	[self dismiss];
	
	return YES;
}

- (void)done:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(inputSheetDidDismiss:)])
	{
		[self.delegate inputSheetDidDismiss:self];
	}
	
	[self dismiss];
}

- (void)cancel:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(inputSheetDidCancel:)])
	{
		[self.delegate inputSheetDidCancel:self];
	}
	
	[self dismiss];
}

- (void)dismiss
{
	[self.textField resignFirstResponder];
	[[self.textField inputAccessoryView] removeFromSuperview];
	[self hideInputView];
}

- (void)hideInputView
{
	CGRect aFrame = [self frame];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(hideDimmingView)];
	
	aFrame.origin.y = 0 - aFrame.size.height;
	[self setFrame:aFrame];
	
	[UIView commitAnimations];
}

- (void)hideDimmingView
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(removeViews)];
	
	[_dimmingView setAlpha:0.0];
	
	[UIView commitAnimations];
}

- (void)removeViews
{
	[_dimmingView removeFromSuperview];
	[self removeFromSuperview];
}

@end
