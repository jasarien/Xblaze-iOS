//
//  JSInputSheet.h
//  JSInputSheet
//
//  Created by James on 07/11/2010.
//  Copyright 2010 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XBInputSheet;

@protocol XBInputSheetDelegate <NSObject>

- (void)inputSheetDidDismiss:(XBInputSheet *)inputSheet;
- (void)inputSheetDidCancel:(XBInputSheet *)inputSheet;

@end


@interface XBInputSheet : UIView <UITextFieldDelegate> {

	UILabel *_titleLabel;
	UITextField *_textField;
	
	UIView *_dimmingView;
	
	id <XBInputSheetDelegate> _delegate;

}

@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UITextField *textField;
@property (nonatomic, assign) id <XBInputSheetDelegate> delegate;

- (id)initWithTitle:(NSString *)title delegate:(id <XBInputSheetDelegate>)delegate;

- (void)show;
- (void)showInView:(UIView *)view;

- (void)hideInputView;

@end
