//
//  XBPasswordInputSheet.h
//  Xblaze-iPhone
//
//  Created by James on 07/11/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBInputSheet.h"

@interface XBPasswordInputSheet : XBInputSheet {

	UITextField *_passwordField;
	
}

@property (nonatomic, retain) UITextField *passwordField;

@end
