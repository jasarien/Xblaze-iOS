//
//  EGOPhotoController.m
//  EGOPhotoViewer
//
//  Created by Devin Doty on 1/8/10.
//  Copyright 2010 enormego. All rights reserved.
//

#import "EGOPhotoViewController.h"
#import "EGOPhotoImageView.h"
#import "EGOPhotoScrollView.h"
#import "EGOCache.h"
#import "EGOPhoto.h"
#import "EGOPhotoSource.h"
#import "EGOPhotoCaptionView.h"

#define IMAGE_GAP 30

@interface EGOPhotoViewController (Private)
- (void)loadScrollViewWithPage:(NSInteger)page;
- (void)layoutScrollViewSubviewsAnimated:(BOOL)animated;
- (void)setupScrollViewContentSize;
- (void)setNavTitle;
- (NSInteger)centerPhotoIndex;
- (void)queueReusablePhotoViewAtIndex:(NSInteger)theIndex;
- (void)setBarsHidden:(BOOL)hidden;
@end


@implementation EGOPhotoViewController

@synthesize scrollView=_scrollView, photoSource=_photoSource, photoViews=_photoViews, captionView=_captionView, storedStyles;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {

		self.wantsFullScreenLayout = YES;
		self.hidesBottomBarWhenPushed = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleBarsNotification:) name:@"EGOPhotoViewToggleBars" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoViewDidFinishLoading:) name:@"EGOPhotoDidFinishLoading" object:nil];
		timer = nil;
		
		pageIndex = 0;
		rotating = NO;
		
	}
	return self;
}

- (id)initWithPhotoSource:(EGOPhotoSource*)aSource{
	if ((self = [self initWithNibName:@"EGOPhotoViewController" bundle:[NSBundle mainBundle]])) {
		_photoSource = [aSource retain];
				
		//	load photoviews lazily
		NSMutableArray *views = [[NSMutableArray alloc] init];
		for (unsigned i = 0; i < [self.photoSource count]; i++) {
			[views addObject:[NSNull null]];
		}
		self.photoViews = views;
		[views release];

		_captionView = [[EGOPhotoCaptionView alloc] initWithFrame:CGRectZero];
		[self.view insertSubview:_captionView atIndex:4];
	}
	
	return self;
}

- (id)initWithImageURL:(NSURL*)aURL {
	EGOPhoto *aPhoto = [[EGOPhoto alloc] initWithImageURL:aURL];
	EGOPhotoSource *source = [[[EGOPhotoSource alloc] initWithEGOPhotos:[NSArray arrayWithObject:aPhoto]] autorelease];
	[aPhoto release];
	
	return [self initWithPhotoSource:source];
}

- (NSArray*)photoToolbarItems{
	actionButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonHit:)] autorelease];

	UIBarButtonItem *flexableSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	
	leftButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"left.png"] style:UIBarButtonItemStylePlain target:self action:@selector(moveBack:)] autorelease];
	rightButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"right.png"] style:UIBarButtonItemStylePlain target:self action:@selector(moveForward:)] autorelease];
		
	return [NSArray arrayWithObjects:flexableSpace, leftButton, flexableSpace, actionButton, flexableSpace, rightButton, flexableSpace, nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.view.backgroundColor = [self.photoSource backgroundColor];
	self.scrollView.backgroundColor = self.view.backgroundColor;
	self.scrollView.opaque = YES;
	
	doubleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewTapped:)] autorelease];
	[doubleTap setNumberOfTapsRequired:2];
	singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewTapped:)] autorelease];
	[singleTap requireGestureRecognizerToFail:doubleTap];
	
	[self.scrollView addGestureRecognizer:doubleTap];
	[self.scrollView addGestureRecognizer:singleTap];
	
	self.wantsFullScreenLayout = YES;
	[self setupScrollViewContentSize];
	[self setToolbarItems:[self photoToolbarItems]]; 

	
	
	[self moveToPhotoAtIndex:0 animated:NO];
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	
	if (!self.storedStyles) {
		self.storedStyles = [EGOStoredBarStyles storeFromController:self];
	}
	
	self.navigationController.navigationBar.tintColor = [self.photoSource navigationBarTintColor];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	self.navigationController.navigationBar.translucent = YES;

	self.navigationController.toolbar.tintColor = nil;
	self.navigationController.toolbar.barStyle = UIBarStyleBlack;
	self.navigationController.toolbar.translucent = YES;
	
	[self.navigationController setToolbarHidden:NO animated:YES];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];

	[self layoutScrollViewSubviewsAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated{
	if (self.storedStyles) {
		[self.storedStyles restoreToController:self withAnimation:animated];
	}
	
	[self setBarsHidden:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	rotating = YES;
	
	if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
		self.scrollView.contentSize = CGSizeMake(480.0f * [self.photoSource count], 320.0f);
	}
	
	//	set side views hidden during rotation animation
	NSInteger count = 0;
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			if (count != pageIndex) {
				[view setHidden:YES];
			}
		}
		count++;
	}
	
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{

	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			[view rotateToOrientation:toInterfaceOrientation];
		}
	}
	
	_captionView.frame = CGRectMake(0.0f, self.view.frame.size.height - (self.navigationController.toolbar.frame.size.height + 40.0f), self.view.frame.size.width, 40.0f);
	
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	
	self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width * [self.photoSource count], self.scrollView.bounds.size.height);

	[self moveToPhotoAtIndex:pageIndex animated:NO];
	[self.scrollView scrollRectToVisible:((EGOPhotoImageView*)[self.photoViews objectAtIndex:pageIndex]).frame animated:YES];
	
	//	unhide side views
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			[view setHidden:NO];
		}
	}
	rotating = NO;
	
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
	{
		[self setBarsHidden:YES];
	}
}

- (void)setBarsHidden:(BOOL)hidden{
	
	if (hidden) {
		if ([[UIApplication sharedApplication] isStatusBarHidden]) {
			return;
		}
		[self.captionView setCaptionHidden:YES];
		[self setStatusBarHidden:YES withAnimation:YES];
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
	} else {
		[self.captionView setCaptionHidden:NO];
		[self setStatusBarHidden:NO withAnimation:YES];
		[self.navigationController setNavigationBarHidden:NO animated:YES];
		[self.navigationController setToolbarHidden:NO animated:YES];
	}
}

- (void)toggleBarsNotification:(NSNotification*)notification{
	
	[self setBarsHidden:![self.navigationController isNavigationBarHidden]];
}

- (void)setNavTitle{
	NSString *formatString = NSLocalizedString(@"%1$i of %2$i", @"Picture X out of Y total.");
	self.title = [NSString stringWithFormat:formatString, pageIndex+1, [self.photoSource count]];
}

- (void)setCaptionTitle{
	[self.captionView setCaptionText:[[self.photoSource photoAtIndex:[self centerPhotoIndex]] imageName]];
}

- (void)setStatusBarHidden:(BOOL)isHidden withAnimation:(BOOL)withAnimation{
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		return; // don't want to hide on iPad.
	}
	
	if ([[UIApplication sharedApplication] respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
		[[UIApplication sharedApplication] setStatusBarHidden:isHidden withAnimation:withAnimation];
	} else {  // Deprecated in iOS 3.2+.
		id sharedApp = [UIApplication sharedApplication];  // Get around deprecation warnings.
		[sharedApp setStatusBarHidden:isHidden animated:withAnimation];
	}
}

- (void)photoViewDidFinishLoading:(NSNotification*)notification{
	
	if (notification == nil) return;
	
	if ([((EGOPhoto*)[[notification object] objectForKey:@"photo"]) isEqual:[self.photoSource photoAtIndex:[self centerPhotoIndex]]]) {
		if ([[[notification object] objectForKey:@"failed"] boolValue]) {
			if ([self.navigationController isNavigationBarHidden]) {
				[self setStatusBarHidden:NO withAnimation:YES];
				[self.navigationController setNavigationBarHidden:NO animated:YES];
				[self.navigationController setToolbarHidden:NO animated:YES];
			} 
		} else {
			[self setCaptionTitle];
		} 
	}
}

- (void)scrollViewTapped:(UITapGestureRecognizer *)recognizer
{
	if (recognizer == doubleTap)
	{
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(toggleBarsNotification:) object:nil];
		EGOPhotoScrollView *photoScrollView = [(EGOPhotoImageView*)[self.photoViews objectAtIndex:[self centerPhotoIndex]] scrollView];
		[photoScrollView zoomRectWithCenter:[recognizer locationInView:photoScrollView]];
	}
	else
	{
		[self performSelector:@selector(toggleBarsNotification:) withObject:nil afterDelay:0];
	}
}

#pragma mark -
#pragma mark ScrollView Methods

- (NSInteger)centerPhotoIndex{
	CGFloat pageWidth = self.scrollView.frame.size.width;
	return floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

- (void)moveForward:(id)sender{
	[self moveToPhotoAtIndex:[self centerPhotoIndex]+1 animated:NO];	
}

- (void)moveBack:(id)sender{
	[self moveToPhotoAtIndex:[self centerPhotoIndex]-1 animated:NO];
}

- (void)moveToPhotoAtIndex:(NSInteger)index animated:(BOOL)animated{

	pageIndex = index;
	
	if ((index >= [self.photoSource count]))
	{
		[self.scrollView scrollRectToVisible:((EGOPhotoImageView*)[self.photoViews lastObject]).frame animated:animated]; //haaaack
		return;	
	}
	else if (index < 0)
	{
		[self.scrollView scrollRectToVisible:((EGOPhotoImageView*)[self.photoViews objectAtIndex:0]).frame animated:animated]; //haaaack
		return;			
	}
	
	leftButton.enabled = !(index-1 < 0);
	rightButton.enabled = !(index+1 >= [self.photoSource count]);
		
	[self queueReusablePhotoViewAtIndex:index];
	
	[self loadScrollViewWithPage:index-1];
	[self loadScrollViewWithPage:index];
	[self loadScrollViewWithPage:index+1];

	[self.scrollView scrollRectToVisible:((EGOPhotoImageView*)[self.photoViews objectAtIndex:index]).frame animated:animated];
	[self setNavTitle];
	
	//	reset any zoomed side views
	if (index + 1 < [self.photoSource count] && (NSNull*)[self.photoViews objectAtIndex:index+1] != [NSNull null]) {
		[((EGOPhotoImageView*)[self.photoViews objectAtIndex:index+1]) killScrollViewZoom];
	} 
	if (index - 1 >= 0 && (NSNull*)[self.photoViews objectAtIndex:index-1] != [NSNull null]) {
		[((EGOPhotoImageView*)[self.photoViews objectAtIndex:index-1]) killScrollViewZoom];
	} 	
	
	[self setCaptionTitle];
	if ([[self.navigationController toolbar] isHidden])
	{
		[self.captionView setCaptionHidden:YES];
	}
}

- (void)layoutScrollViewSubviewsAnimated:(BOOL)animated{
	
	NSInteger page = [self centerPhotoIndex];
	CGRect imageFrame = self.scrollView.frame;
	
	
	if (page < 0) return;
	if (page >= [self.photoSource count]) return;
	
	if (animated) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:.1];
	}
	
		//	layout center
		if (page >= 0 && page < [self.photoSource count]){
			if ([self.photoViews objectAtIndex:page] != [NSNull null]){
				[((EGOPhotoImageView*)[self.photoViews objectAtIndex:page]) setFrame:CGRectMake(imageFrame.size.width * page, 0.0f, imageFrame.size.width, imageFrame.size.height)];
			}
		}
	
		//	layout left
		if (page-1 >= 0){
			if (page-1	>= 0 && [self.photoViews objectAtIndex:page -1] != [NSNull null]){
				[((EGOPhotoImageView*)[self.photoViews objectAtIndex:page -1]) setFrame:CGRectMake((imageFrame.size.width * (page -1)) - IMAGE_GAP, 0.0f, imageFrame.size.width, imageFrame.size.height)];
			}
		}
		
		//	layout right
		if (page+1 <= [self.photoSource count]) 
			if (page+1 < [self.photoSource count] && [self.photoViews objectAtIndex:page +1] != [NSNull null]){
				[((EGOPhotoImageView*)[self.photoViews objectAtIndex:page +1]) setFrame:CGRectMake((imageFrame.size.width * (page +1)) + IMAGE_GAP, 0.0f, imageFrame.size.width, imageFrame.size.height)];		
			}
	
	if (animated) {
		[UIView commitAnimations];
	}
}

- (void)setupScrollViewContentSize{
	CGRect screenFrame = [[UIScreen mainScreen] bounds];
	
	if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
		self.scrollView.contentSize = CGSizeMake([[UIScreen mainScreen] bounds].size.height * [self.photoSource count], 320.0f);
		_captionView.frame = CGRectMake(0.0f, screenFrame.size.width - (32.0f + 40.0f), screenFrame.size.height, 40.0f);
	} else {
		self.scrollView.contentSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width * [self.photoSource count], 480.0f);
		_captionView.frame = CGRectMake(0.0f, screenFrame.size.height - (44.0f + 40.0f), screenFrame.size.width, 40.0f);
	}
}

- (void)queueReusablePhotoViewAtIndex:(NSInteger)theIndex{
	NSInteger count = 0;
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			if (count > theIndex+1 || count < theIndex-1) {
				[view prepareForReuse];
				[view removeFromSuperview];
			} else {
				view.tag = 0;
			}
	
		} 
		count++;
	}	
}

- (EGOPhotoImageView*)dequeueReusablePhotoView{
	NSInteger count = 0;
	for (EGOPhotoImageView *view in self.photoViews){
		if ([view isKindOfClass:[EGOPhotoImageView class]]) {
			if (view.superview == nil) {
				view.tag = count;
				return view;
			}
		}
		count ++;
	}	
	return nil;
}

- (void)loadScrollViewWithPage:(NSInteger)page {
	
		if (page < 0) return;
		if (page >= [self.photoSource count]) return;
		
		// replace the placeholder if necessary 	
	EGOPhotoImageView * photoView = [self.photoViews objectAtIndex:page];
	if ((NSNull*)photoView == [NSNull null]) {
		//	recycle an image view if one is free
		photoView = [self dequeueReusablePhotoView];
		if (photoView != nil) {
			[self.photoViews exchangeObjectAtIndex:photoView.tag withObjectAtIndex:page];
			photoView = [self.photoViews objectAtIndex:page];
		}
	}
	
	//	create a new image view if necessary 
	if (photoView == nil || (NSNull*)photoView == [NSNull null]) {
		photoView = [[EGOPhotoImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height)];
		photoView.backgroundColor = self.view.backgroundColor;
		[photoView.scrollView setBackgroundColor:self.view.backgroundColor];

		[self.photoViews replaceObjectAtIndex:page withObject:photoView];
		[photoView release];
	} 
	
	[photoView setPhoto:((EGOPhoto*)[self.photoSource photoAtIndex:page])];

		// add the image view to the scroll view if necessary
		if (photoView.superview == nil) {
		[self.scrollView addSubview:photoView];
	}
	
	//	layout image views frame
	CGRect frame = self.scrollView.frame;
	NSInteger centerPageIndex = pageIndex;
	CGFloat xOrigin = (frame.size.width * page);
	if (page > centerPageIndex) {
		xOrigin = (frame.size.width * page) + IMAGE_GAP;
	} else if (page < centerPageIndex) {
		xOrigin = (frame.size.width * page) - IMAGE_GAP;
	}
		
	frame.origin.x = xOrigin;
	frame.origin.y = 0;
	photoView.frame = frame;
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {

	if (pageIndex != [self centerPhotoIndex] && !rotating) {
		NSInteger newIndex = [self centerPhotoIndex];
		if (newIndex >= [self.photoSource count] || newIndex < 0) {
			return;
		}
		[self setBarsHidden:YES];
		pageIndex = newIndex;
		[self layoutScrollViewSubviewsAnimated:YES];
		[self setNavTitle];
		[self.captionView setCaptionText:@""];
		
		//	rare case: if the user is scrolling quickly scrollViewDidEndDecelerating may no get called
		//	make sure new center has an image
		if ((NSNull*)[self.photoViews objectAtIndex:pageIndex] == [NSNull null]) {
			[self loadScrollViewWithPage:pageIndex];
		}
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
	[self moveToPhotoAtIndex:[self centerPhotoIndex] animated:YES];
	[self layoutScrollViewSubviewsAnimated:NO];
	
}


#pragma mark -
#pragma mark Sharing Methods

- (void)savePhoto{
	UIImageWriteToSavedPhotosAlbum(((EGOPhotoImageView*)[self.photoViews objectAtIndex:pageIndex]).imageView.image, nil, nil, nil);
}

- (void)copyPhoto{
	
	EGOPhoto * photo = [(EGOPhotoImageView*)[self.photoViews objectAtIndex:pageIndex] photo];
	NSURL *url = [photo imageURL];
	
	[[UIPasteboard generalPasteboard] setString:[url absoluteString]];
}

- (void)emailPhoto{
	MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
	[mailViewController setSubject:NSLocalizedString(@"Check out this screenshot!", @"Email subject when sharing a photo.")];
	[mailViewController addAttachmentData:[NSData dataWithData:UIImagePNGRepresentation(((EGOPhotoImageView*)[self.photoViews objectAtIndex:pageIndex]).imageView.image)] mimeType:@"png" fileName:@"Photo.png"];
	mailViewController.mailComposeDelegate = self;
	[self presentModalViewController:mailViewController animated:YES];
	[mailViewController release];
	
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
	{
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	[self dismissModalViewControllerAnimated:YES];
	
	switch (result)
	{
		case MFMailComposeResultSaved:
		{
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Message Saved"
															 message:@"Your message has been saved.\nYou may send it at a later date."
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] autorelease];
			[alert show];
		}
		case MFMailComposeResultFailed:
		{
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Sending Failed"
															 message:@"The message was unable to be sent.\nPlease try again."
															delegate:nil
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] autorelease];
			[alert show];
		}	
		case MFMailComposeResultCancelled:
		case MFMailComposeResultSent:
			break;
		default:
			break;
	}
}

#pragma mark -
#pragma mark ActionSheet Methods

- (void)actionButtonHit:(id)sender{
	
	if (actionSheet)
	{
		return;
	}
	
	if ([MFMailComposeViewController canSendMail]) {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@""
																							delegate:self 
																		 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
																destructiveButtonTitle:nil 
																		 otherButtonTitles:NSLocalizedString(@"Save screenshot", nil), NSLocalizedString(@"Copy link to screenshot", nil), NSLocalizedString(@"Email screenshot", nil), nil];
	} else {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"" 
																							delegate:self 
																		 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
																destructiveButtonTitle:nil 
																		 otherButtonTitles:NSLocalizedString(@"Save screenshot", nil), NSLocalizedString(@"Copy link to screenshot", nil), nil];
	}
	
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[actionSheet showFromBarButtonItem:sender animated:YES];
	}
	else
	{
		[actionSheet showInView:self.view];
	}
	
	actionSheet.delegate = self;
	[actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)anActionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
	
	[self setBarsHidden:NO];
	
	if (buttonIndex == actionSheet.cancelButtonIndex) {
		return;
	} else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
		[self savePhoto];
	} else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
		[self copyPhoto];	
	} else if (buttonIndex == actionSheet.firstOtherButtonIndex + 2) {
		[self emailPhoto];
	}
	
	actionSheet = nil;
}

- (void)actionSheet:(UIActionSheet *)anActionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	actionSheet = nil;
}

- (void)actionSheetCancel:(UIActionSheet *)anActionSheet
{
	actionSheet = nil;
}


#pragma mark -
#pragma mark Memory

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"EGOPhotoDidFinishLoading" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"EGOPhotoViewToggleBars" object:nil];
	
	timer = nil;
	[_photoViews release], _photoViews=nil;
	[_photoSource release], _photoSource=nil;
	[_captionView release], _captionView=nil;
	[_scrollView release], _scrollView=nil;
	
	self.storedStyles = nil;
	
		[super dealloc];
}


@end
