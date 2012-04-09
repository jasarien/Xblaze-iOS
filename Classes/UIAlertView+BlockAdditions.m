#import "UIAlertView+BlockAdditions.h"
#import <objc/runtime.h>

NSString * const UIAlertViewCompletionHandlerKey = @"UIAlertViewCompletionHandlerKey";

@implementation UIAlertView (BlockAdditions)

- (UIAlertViewCompletionHandler)completionHandler
{
	UIAlertViewCompletionHandler handler = (UIAlertViewCompletionHandler)objc_getAssociatedObject(self, UIAlertViewCompletionHandlerKey);
	return handler;
}

- (void)setCompletionHandler:(UIAlertViewCompletionHandler)handler
{
	self.delegate = (id<UIAlertViewDelegate>)self;
	
	objc_setAssociatedObject(self, UIAlertViewCompletionHandlerKey, handler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	UIAlertViewCompletionHandler handler = (UIAlertViewCompletionHandler)objc_getAssociatedObject(self, UIAlertViewCompletionHandlerKey);
	
	if(handler)
	{
		handler(buttonIndex);
	}
	
	objc_setAssociatedObject(self, UIAlertViewCompletionHandlerKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
