//
//  EGOThumbsViewController.m
//  EGOPhotoViewer
//
//  Created by Henrik Nyh on 2010-06-25.
//  Copyright 2010 Henrik Nyh. All rights reserved.
//

#import "EGOThumbsViewController.h"
#import "EGOPhotoViewController.h"

@implementation EGOThumbsViewController

@synthesize photoSource=_photoSource, storedStyles;

- (id)initWithPhotoSource:(EGOPhotoSource*)aSource {
	if ((self = [super init])) {
		
		self.wantsFullScreenLayout = YES;
		self.title = NSLocalizedString(@"Pictures", nil);
		
		_photoSource = [aSource retain];
		
	}
	return self;
}

- (void)loadView {
	
	_scrollView = [[EGOThumbsScrollView alloc] initWithFrame:CGRectZero];
	_scrollView.photoSource = _photoSource;
	_scrollView.controller = self;
	self.view = _scrollView;
	
}

- (void)viewDidLoad {
	self.view.backgroundColor = [self.photoSource thumbnailBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	
	if (!self.storedStyles) {
		self.storedStyles = [EGOStoredBarStyles storeFromController:self];
	}
	
	self.navigationController.navigationBar.tintColor = [self.photoSource navigationBarTintColor];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	self.navigationController.navigationBar.translucent = YES;
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated{	
	if (self.storedStyles) {
		[self.storedStyles restoreToController:self withAnimation:animated];
	}
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 	return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];		
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[_scrollView release], _scrollView = nil;
}


#pragma mark -

- (void)didSelectThumbAtIndex:(NSInteger)index {
	EGOPhotoViewController *photoController = [[EGOPhotoViewController alloc] initWithPhotoSource:self.photoSource];
	[self.navigationController pushViewController:photoController animated:YES];
	[photoController moveToPhotoAtIndex:index animated:NO];
	[photoController release];
}

#pragma mark -

- (void)dealloc {
	[_photoSource release], _photoSource = nil;
	[_scrollView release], _scrollView = nil;
	self.storedStyles = nil;
	[super dealloc];
}


@end
