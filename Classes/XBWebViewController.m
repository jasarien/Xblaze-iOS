//
//  XBWebViewController.m
//  Xblaze-iPhone
//
//  Created by James on 13/12/2009.
//  Copyright 2009 JamSoft. All rights reserved.
//

#import "XBWebViewController.h"
#import "XBNetworkActivityIndicatorManager.h"

@implementation XBWebViewController

@synthesize webView = _webView;

@synthesize spinner = _spinner;

@synthesize toolbar = _toolbar;

@synthesize backButton = _backButton;
@synthesize forwardButton = _forwardButton;
@synthesize refreshButton = _refreshButton;
@synthesize openInSafariButton = _openInSafariButton;

@synthesize url = _url;
@synthesize baseURL = _baseURL;
@synthesize htmlString = _htmlString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil url:(NSURL *)url
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		app = (Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.url = url;
		self.htmlString = nil;
		[self setHidesBottomBarWhenPushed:YES];
    }
	
    return self;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil htmlString:(NSString *)htmlString baseURL:(NSURL *)baseURL
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		app = (Xblaze_iPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.url = nil;
		self.baseURL = baseURL;
		self.htmlString = htmlString;
		[self setHidesBottomBarWhenPushed:YES];
    }
	
    return self;	
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self.navigationItem setTitle:@"Loading..."];
	
	if (self.url)
	{
		NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
		[self.webView loadRequest:request];
	}
	else if (self.htmlString)
	{
		[self.webView loadHTMLString:self.htmlString baseURL:self.baseURL];
	}	
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self validateButtons];
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
	self.webView.delegate = nil;
	self.webView = nil;

	self.spinner = nil;
	
	self.toolbar = nil;
	
	self.backButton = nil;
	self.forwardButton = nil;
	self.refreshButton = nil;
	self.openInSafariButton = nil;
	
}

- (IBAction)openInSafari
{
	UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:@"Open in Safari?"
															  delegate:self
													 cancelButtonTitle:@"Cancel"
												destructiveButtonTitle:nil
													 otherButtonTitles:@"OK", nil] autorelease];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[actionSheet showFromBarButtonItem:self.openInSafariButton animated:YES];
	}
	else
	{
		[actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
		[actionSheet showInView:[self view]];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if ([actionSheet cancelButtonIndex] != buttonIndex)
	{
		NSURL *urlToOpen = nil;
		
		if ([[self.webView request] URL])
		{
			urlToOpen = [[self.webView request] URL];
		}
		else
		{
			urlToOpen = self.url;
		}
		
		[[UIApplication sharedApplication] openURL:urlToOpen];
	}
}

- (void)validateButtons
{
	if ([self.webView canGoBack])
	{
		[self.backButton setEnabled:YES];
	}
	else
	{
		[self.backButton setEnabled:NO];
	}
	
	if ([self.webView canGoForward])
	{
		[self.forwardButton setEnabled:YES];
	}
	else
	{
		[self.forwardButton setEnabled:NO];
	}

}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	[self validateButtons];
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[self.spinner stopAnimating];
	[XBNetworkActivityIndicatorManager hideNetworkActivity];
	[self validateButtons];
	[self.navigationItem setTitle:[self.webView stringByEvaluatingJavaScriptFromString:@"document.title"]];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[self.spinner startAnimating];
	[XBNetworkActivityIndicatorManager showNetworkActivity];
	[self validateButtons];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[self.spinner stopAnimating];
	[XBNetworkActivityIndicatorManager hideNetworkActivity];
	
	[self validateButtons];
	
	switch ([error code])
	{
		case BrowserErrorOperationNotCompleted:
			break;
		case BrowserErrorNoInternetConnection:
		case BrowserErrorHostNotFound:
		{
			NSString *pathToErrorPage = [[NSBundle mainBundle] pathForResource:@"error" ofType:@"html"];
			NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:pathToErrorPage]];
			[self.webView loadRequest:request];
		}
		default:
			break;
	}
}

- (void)dealloc
{
	[XBNetworkActivityIndicatorManager hideNetworkActivity];
	self.url = nil;
	
	self.webView.delegate = nil;
	self.webView = nil;
	
	self.spinner = nil;
	
	self.toolbar = nil;
	
	self.backButton = nil;
	self.forwardButton = nil;
	self.refreshButton = nil;
	self.openInSafariButton = nil;
	
	
    [super dealloc];
}


@end
