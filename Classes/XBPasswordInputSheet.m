//
//  XBPasswordInputSheet.m
//  Xblaze-iPhone
//
//  Created by James on 07/11/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import "XBPasswordInputSheet.h"

@implementation XBPasswordInputSheet

@synthesize passwordField = _passwordField;

- (id)initWithTitle:(NSString *)title delegate:(id <XBInputSheetDelegate>)delegate
{
	if ((self = [super initWithTitle:title delegate:delegate]))
	{
		[self setFrame:CGRectMake(0, 0, 320, 139)];
		
		self.passwordField = [[[UITextField alloc] initWithFrame:CGRectMake(20, 88, 280, 31)] autorelease];
		[self.passwordField setBorderStyle:UITextBorderStyleRoundedRect];
		[self.passwordField setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[self.passwordField setDelegate:self];
		[self.passwordField setKeyboardAppearance:UIKeyboardAppearanceAlert];
		[self.passwordField setReturnKeyType:UIReturnKeyDone];
		[self.passwordField setSecureTextEntry:YES];
		
		[self addSubview:self.passwordField];
		
		[self.passwordField setInputAccessoryView:[self.textField inputAccessoryView]];
	}
	
	return self;
}

- (void)dismiss
{
	[self.textField resignFirstResponder];
	[self.passwordField resignFirstResponder];
	[self hideInputView];
}

- (void)dealloc
{
	self.passwordField = nil;
	
	[super dealloc];
}


@end
