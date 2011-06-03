//
//  XBChatMessageCell.h
//  Xblaze-iPhone
//
//  Created by James on 25/11/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSCoreTextView.h"

@class XBChatMessageCell, AHMarkedHyperlink;

@protocol XBChatMessageCellDelegate <NSObject>

- (void)chatMessageCell:(XBChatMessageCell *)chatMessageCell didSelectLink:(AHMarkedHyperlink *)link;

@end

@interface XBChatMessageCell : UITableViewCell <JSCoreTextViewDelegate> {
	
	id <XBChatMessageCellDelegate> _delegate;
	
	UILabel *_usernameLabel;
	JSCoreTextView *_messageView;
	
}

@property (nonatomic, assign) id <XBChatMessageCellDelegate> delegate;

@property (nonatomic, readonly) UILabel *usernameLabel;
@property (nonatomic, readonly) JSCoreTextView *messageView;

+ (CGFloat)paddingTop;
+ (CGFloat)paddingLeft;
+ (CGFloat)padding;
+ (NSString *)fontName;
+ (CGFloat)fontSize;
+ (CGFloat)nameHeight;

- (void)setMessageText:(NSString *)messageText;

@end