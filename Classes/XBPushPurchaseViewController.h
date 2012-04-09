//
//  XBPushPurchaseViewController.h
//  Xblaze-iPhone
//
//  Created by James Addyman on 08/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MAConfirmButton;

@interface XBPushPurchaseViewController : UIViewController {
	
	MAConfirmButton *_purchaseButton;
	
}

@property (retain, nonatomic) IBOutlet UIImageView *iconView;
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *priceDetailLabel;
@property (retain, nonatomic) IBOutlet UILabel *descriptionLabel;

- (IBAction)moreInfo:(id)sender;
- (IBAction)restore:(id)sender;
- (IBAction)purchase:(id)sender;

@end
