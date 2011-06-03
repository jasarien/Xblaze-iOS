//
//  XBWebViewController.h
//  Xblaze-iPhone
//
//  Created by James on 13/12/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Xblaze_iPhoneAppDelegate.h"

typedef enum {
	
	BrowserErrorHostNotFound = -1003,
	BrowserErrorOperationNotCompleted = -999,
	BrowserErrorNoInternetConnection = -1009
	
} BrowserErrorCode;

@interface XBWebViewController : UIViewController <UIActionSheetDelegate> {

	UIWebView *_webView;
	
	UIActivityIndicatorView *_spinner;
	
	UIToolbar *_toolbar;
	
	UIBarButtonItem *_backButton;
	UIBarButtonItem *_forwardButton;
	UIBarButtonItem *_refreshButton;
	UIBarButtonItem *_openInSafariButton;
	
	NSURL *_url, *_baseURL;
	NSString *_htmlString;
	
	Xblaze_iPhoneAppDelegate *app;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;

@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *refreshButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *openInSafariButton;

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSURL *baseURL;
@property (nonatomic, retain) NSString *htmlString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil url:(NSURL *)url;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil htmlString:(NSString *)htmlString baseURL:(NSURL *)baseURL;

- (IBAction)openInSafari;

- (void)validateButtons;

@end
