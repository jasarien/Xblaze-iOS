#import <UIKit/UIKit.h>

typedef void(^UIAlertViewCompletionHandler)(NSUInteger buttonIndex);

@interface UIAlertView (BlockAdditions)

- (UIAlertViewCompletionHandler)completionHandler;
- (void)setCompletionHandler:(UIAlertViewCompletionHandler)handler;

@end
