//  The MIT License (MIT)
//
//  Copyright (c) 2015 Ermal Kaleci
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#define INDICATOR_WIDTH		3.f

#import "CarbonTabSwipeNavigation.h"
#import "CarbonTabSwipeView.h"

@interface CarbonTabSwipeNavigation() <UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate> {
	
	BOOL isNotDragging;
	
	NSUInteger numberOfTabs;
	NSInteger selectedIndex;
	
	CGPoint previewsOffset;
	
	NSMutableArray *tabs;
	NSMutableArray *tabNames;
	NSMutableDictionary *viewControllers;
	
	__weak UIViewController *rootViewController;
	UIPageViewController *pageController;
	CarbonTabSwipeView *tabSwipeView;
}

@end

@implementation CarbonTabSwipeNavigation

@synthesize currentTabIndex = _currentTabIndex;

- (instancetype)createWithRootViewController:(UIViewController *)viewController
									tabNames:(NSArray *)names
								   tintColor:(UIColor *)tintColor
									delegate:(id)delegate {
	return [self createWithRootViewController:viewController
									 tabNames:names
									tintColor:tintColor
							 startingTabIndex:0
									 delegate:delegate];
}

- (instancetype)createWithRootViewController:(UIViewController *)viewController
									tabNames:(NSArray *)names
								   tintColor:(UIColor *)tintColor
							startingTabIndex:(NSUInteger)startingTabIndex
									delegate:(id)delegate {
	// init
	self.delegate = delegate;
	numberOfTabs = names.count;
	rootViewController = viewController;
	tabs = [[NSMutableArray alloc] init];
	tabNames = [NSMutableArray arrayWithArray:names];
	viewControllers = [[NSMutableDictionary alloc] init];
	selectedIndex = startingTabIndex;
	
	// add self as child to parent
	[rootViewController addChildViewController:self];
	[rootViewController.view addSubview:self.view];
	
 
	[self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
	
	// setup the constraints
	UIView *parentView = self.view;
	id<UILayoutSupport> rootTopLayoutGuide = rootViewController.topLayoutGuide;
	id<UILayoutSupport> rootBottomLayoutGuide = rootViewController.bottomLayoutGuide;
	NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(rootTopLayoutGuide, rootBottomLayoutGuide, parentView);
	
	
	[rootViewController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[rootTopLayoutGuide][parentView][rootBottomLayoutGuide]" options:0 metrics:nil views:viewsDictionary]];
	[rootViewController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[parentView]|" options:0 metrics:nil views:viewsDictionary]];
	
	// finish adding self as child to parent
	[self didMoveToParentViewController:rootViewController];
	
	
	
	// set tint color
	//[self setTintColor:tintColor];
	
	
	
	return self;
}

// TODO: remove these color setters, in favor of UIAppearance proxy support
- (void)setTintColor:(UIColor *)tintColor {
	//	tabScrollView.backgroundColor = tintColor;
	//	[rootViewController.navigationController.navigationBar setBarTintColor:tintColor];
}

- (void)setNormalColor:(UIColor *)color {
	//	[self setNormalColor:color font:[UIFont boldSystemFontOfSize:14]];
}

- (void)setNormalColor:(UIColor *)color font:(UIFont *)font {
	//	[segmentController setTitleTextAttributes:@{
	//												NSForegroundColorAttributeName:color,
	//												NSFontAttributeName:font
	//												}
	//									 forState:UIControlStateNormal];
}

- (void)setSelectedColor:(UIColor *)color {
	[self setSelectedColor:color font:[UIFont boldSystemFontOfSize:14]];
}

- (void)setSelectedColor:(UIColor *)color font:(UIFont *)font {
	//	indicator.backgroundColor = color;
	//	[segmentController setTitleTextAttributes:@{
	//												NSForegroundColorAttributeName:color,
	//												NSFontAttributeName:font
	//												}
	//									 forState:UIControlStateSelected];
}

- (void)segmentAction:(UISegmentedControl *)segment {
	UIView *tab = tabs[tabSwipeView.segmentController.selectedSegmentIndex];
	tabSwipeView.indicatorWidthConst.constant = tab.frame.size.width;
	tabSwipeView.indicatorLeftConst.constant = tab.frame.origin.x;
	
	NSInteger index = tabSwipeView.segmentController.selectedSegmentIndex;
	
	if (index == selectedIndex) return;
	
	if (index >= numberOfTabs)
		return;
	
	UIViewController *viewController = [viewControllers objectForKey:[NSNumber numberWithInteger:index]];
	
	if (!viewController) {
		viewController = [self.delegate tabSwipeNavigation:self viewControllerAtIndex:index];
		[viewControllers setObject:viewController forKey:[NSNumber numberWithInteger:index]];
	}
	
	[viewController.view layoutIfNeeded];
	
	UIPageViewControllerNavigationDirection animateDirection
	= index > selectedIndex
	? UIPageViewControllerNavigationDirectionForward
	: UIPageViewControllerNavigationDirectionReverse;
	
	__weak __typeof__(self) weakSelf = self;
	isNotDragging = YES;
	pageController.view.userInteractionEnabled = NO;
	[pageController setViewControllers:@[viewController]
							 direction:animateDirection
							  animated:NO
							completion:^(BOOL finished) {
								__strong __typeof__(self) strongSelf = weakSelf;
								strongSelf->isNotDragging = NO;
								strongSelf->pageController.view.userInteractionEnabled = YES;
								strongSelf->selectedIndex = index;
								[strongSelf->tabSwipeView.segmentController setSelectedSegmentIndex:strongSelf->selectedIndex];
								[strongSelf fixOffset];
								
								// call delegate
								if ([strongSelf->_delegate respondsToSelector:@selector(tabSwipeNavigation:didMoveAtIndex:)]) {
									[strongSelf->_delegate tabSwipeNavigation:strongSelf didMoveAtIndex:index];
								}
							}];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	
	// create page controller
	pageController = [UIPageViewController alloc];
	pageController = [pageController initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
									   navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
													 options:nil];
	pageController.delegate = self;
	pageController.dataSource = self;
	
	// delegate scrollview
	for (UIView *v in pageController.view.subviews) {
		if ([v isKindOfClass:[UIScrollView class]]) {
			((UIScrollView *)v).delegate = self;
		}
	}
	
	// add subviews to self
	tabSwipeView = [[CarbonTabSwipeView alloc] initWithSegmentTitles:tabNames];
	[tabSwipeView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self.view addSubview:tabSwipeView];
	
	// add page controller as child to self
	[self addChildViewController:pageController];
	[self.view addSubview:pageController.view];
	
	[pageController.view setTranslatesAutoresizingMaskIntoConstraints: NO];
	
	// create constraints
	UIView *pageControllerView = pageController.view;
	NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(tabSwipeView, pageControllerView);
	NSDictionary *metricsDictionary = @{
										@"tabSwipeViewHeight" : @45
										};
	
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tabSwipeView(==tabSwipeViewHeight)][pageControllerView]|" options:0 metrics:metricsDictionary views:viewsDictionary]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tabSwipeView]|" options:0 metrics:metricsDictionary views:viewsDictionary]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pageControllerView]|" options:0 metrics:metricsDictionary views:viewsDictionary]];
	
	// finish adding page controller as child of self
	[pageController didMoveToParentViewController:self];
	
	// add the segment controller action
	[tabSwipeView.segmentController addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	
	// cache the tabs
	for (UIView *tabView in [tabSwipeView.segmentController subviews]) {
		if (tabView != tabSwipeView.indicator) {
			[tabs addObject:tabView];
		}
	}
	
	// default view controller index
	tabSwipeView.segmentController.selectedSegmentIndex = selectedIndex;
}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (!pageController.viewControllers.count) {
		// first view controller
		id viewController = [self.delegate tabSwipeNavigation:self viewControllerAtIndex:selectedIndex];
		
		
		if (viewController) {
			[viewControllers setObject:viewController forKey:[NSNumber numberWithInteger:selectedIndex]];
			
			__weak __typeof__(self) weakSelf = self;
			[pageController setViewControllers:@[viewController]
									 direction:UIPageViewControllerNavigationDirectionForward
									  animated:NO
									completion:^(BOOL finished) {
										__strong __typeof__(self) strongSelf = weakSelf;
										// call delegate
										if ([strongSelf->_delegate respondsToSelector:@selector(tabSwipeNavigation:didMoveAtIndex:)]) {
											[strongSelf->_delegate tabSwipeNavigation:strongSelf didMoveAtIndex:strongSelf->selectedIndex];
										}
									}];
			
		}
	}
	
	[self fixOffset];
	
	tabSwipeView.indicatorLeftConst.constant = ((UIView*)tabs[selectedIndex]).frame.origin.x;
	tabSwipeView.indicatorWidthConst.constant = ((UIView*)tabs[selectedIndex]).frame.size.width;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	// hide the indicator if were going to be rotating to a completely new orientation (portrait vs landscape)
	if (!((UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) ||
		  (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && UIInterfaceOrientationIsPortrait(toInterfaceOrientation)))) {
		[UIView animateWithDuration:duration animations:^{
			// hide the indicator during rotation
			tabSwipeView.indicator.alpha = 0.0f;
		}];
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	if (tabSwipeView.indicator.alpha < 1.0f) {
		// fix indicator position and width
		tabSwipeView.indicatorLeftConst.constant = ((UIView*)tabs[selectedIndex]).frame.origin.x;
		tabSwipeView.indicatorWidthConst.constant = ((UIView*)tabs[selectedIndex]).frame.size.width;
		
		[self fixOffset];
		
		// show the indicator
		tabSwipeView.indicator.alpha = 1.0f;
	}
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	UIView *tab = tabs[tabSwipeView.segmentController.selectedSegmentIndex];
	tabSwipeView.indicatorWidthConst.constant = tab.frame.size.width;
	tabSwipeView.indicatorLeftConst.constant = tab.frame.origin.x;
	
	// keep the page controller's width in sync
	pageController.view.frame = CGRectMake(pageController.view.frame.origin.x, pageController.view.frame.origin.y, self.view.bounds.size.width, pageController.view.frame.size.height);
	
	[self resizeTabs];
	[self fixOffset];
	[self.view layoutIfNeeded];
}

- (void)fixOffset {
	CGRect selectedTabRect = ((UIView*)tabs[selectedIndex]).frame;
	CGFloat indicatorMaxOriginX = tabSwipeView.tabScrollView.frame.size.width / 2 - selectedTabRect.size.width / 2;
	
	CGFloat offsetX = selectedTabRect.origin.x-indicatorMaxOriginX;
	
	if (offsetX < 0) offsetX = 0;
	if (offsetX > tabSwipeView.segmentController.frame.size.width-tabSwipeView.tabScrollView.frame.size.width)
		offsetX = tabSwipeView.segmentController.frame.size.width-tabSwipeView.tabScrollView.frame.size.width;
	
	[UIView animateWithDuration:0.3 animations:^{
		tabSwipeView.tabScrollView.contentOffset = CGPointMake(offsetX, 0);
	}];
	
	previewsOffset = CGPointMake(offsetX, 0);
}

- (void)resizeTabs {
	// view size
	CGSize size = self.view.frame.size;
	
	// max tabWidth
	CGFloat maxTabWidth = 0;
	
	// get tabs width
	NSUInteger i = 0;
	CGFloat segmentedWidth = 0;
	
	for (UIView *tabView in tabs) {
		for (UIView *label in tabView.subviews) {
			if ([label isKindOfClass:[UILabel class]]) {
				UILabel *myLabel = (UILabel*)label;
				CGSize size = [myLabel.text sizeWithAttributes:@{NSFontAttributeName : tabSwipeView.tabTitleTextFont}];
				CGFloat tabWidth = roundf(size.width + 30.0f); //roundf([label sizeThatFits:CGSizeMake(FLT_MAX, 0)].width + 30); // 30 extra space
				[tabSwipeView.segmentController setWidth:tabWidth forSegmentAtIndex:i];
				
				segmentedWidth += tabWidth;
				
				// get max tab width
				maxTabWidth = tabWidth > maxTabWidth ? tabWidth : maxTabWidth;
			}
		}
		i++;
	}
	
	// segment width not fill the view width
	if (segmentedWidth < size.width) {
		
		// tabs width as max tab width or calcucate it
		if (size.width / (float)numberOfTabs < maxTabWidth) {
			
			for (int i = 0; i < numberOfTabs; i++) {
				[tabSwipeView.segmentController setWidth:maxTabWidth forSegmentAtIndex:i];
			}
			
			segmentedWidth = maxTabWidth * numberOfTabs;
		} else {
			maxTabWidth = roundf(size.width/(float)numberOfTabs);
			
			for (int i = 0; i < numberOfTabs; i++) {
				[tabSwipeView.segmentController setWidth:maxTabWidth forSegmentAtIndex:i];
			}
			
			segmentedWidth = size.width;
		}
	}
	
	tabSwipeView.segmentControllerWidthConst.constant = segmentedWidth;
}

#pragma mark - Public API
- (NSUInteger)currentTabIndex
{
	return selectedIndex;
}

- (void)setCurrentTabIndex:(NSUInteger)currentTabIndex
{
	if (selectedIndex != currentTabIndex && currentTabIndex < numberOfTabs) {
		tabSwipeView.segmentController.selectedSegmentIndex = currentTabIndex;
		
		[self segmentAction:tabSwipeView.segmentController];
	}
}

# pragma mark - PageViewController DataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
	   viewControllerAfterViewController:(UIViewController *)viewController {
	
	NSInteger index = selectedIndex;
	
	if (index++ < numberOfTabs - 1 && index <= numberOfTabs - 1) {
		
		UIViewController *nextViewController = [viewControllers objectForKey:[NSNumber numberWithInteger:index]];
		
		if (!nextViewController) {
			nextViewController = [self.delegate tabSwipeNavigation:self viewControllerAtIndex:index];
			[viewControllers setObject:nextViewController forKey:[NSNumber numberWithInteger:index]];
		}
		
		return nextViewController;
	}
	
	return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
	  viewControllerBeforeViewController:(UIViewController *)viewController {
	
	NSInteger index = selectedIndex;
	
	if (index-- > 0) {
		UIViewController *nextViewController = [viewControllers objectForKey:[NSNumber numberWithInteger:index]];
		
		if (!nextViewController) {
			nextViewController = [self.delegate tabSwipeNavigation:self viewControllerAtIndex:index];
			[viewControllers setObject:nextViewController forKey:[NSNumber numberWithInteger:index]];
		}
		
		return nextViewController;
	}
	
	return nil;
}

# pragma mark - PageViewController Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController
		didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
	   transitionCompleted:(BOOL)completed {
	
	if (!completed)
		return;
	
	id currentView = [pageViewController.viewControllers objectAtIndex:0];
	
	NSNumber *key = (NSNumber*)[viewControllers allKeysForObject:currentView][0];
	selectedIndex= [key integerValue];
	
	[tabSwipeView.segmentController setSelectedSegmentIndex:selectedIndex];
	
	// call delegate
	if ([self.delegate respondsToSelector:@selector(tabSwipeNavigation:didMoveAtIndex:)]) {
		[self.delegate tabSwipeNavigation:self didMoveAtIndex:selectedIndex];
	}
}

# pragma mark - ScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	
	CGPoint offset = scrollView.contentOffset;
	
	CGFloat scrollViewWidth = scrollView.frame.size.width;
	if (selectedIndex < 0 || selectedIndex > numberOfTabs-1)
		return;
	
	if (!isNotDragging) {
		
		if (offset.x < scrollViewWidth) {
			// we are moving back
			
			if (selectedIndex - 1 < 0)
				return;
			
			float newX = offset.x - scrollViewWidth;
			
			UIView *selectedTab = (UIView*)tabs[selectedIndex];
			UIView *backTab = (UIView*)tabs[selectedIndex - 1];
			
			float selectedOriginX = selectedTab.frame.origin.x;
			float backTabWidth = backTab.frame.size.width;
			
			float widthDiff = selectedTab.frame.size.width - backTabWidth;
			
			float newOriginX = selectedOriginX + newX / scrollViewWidth * backTabWidth;
			tabSwipeView.indicatorLeftConst.constant = newOriginX;
			
			float newWidth = selectedTab.frame.size.width + newX / scrollViewWidth * widthDiff;
			tabSwipeView.indicatorWidthConst.constant = newWidth;
			
			[UIView animateWithDuration:0.01 animations:^{
				[tabSwipeView.indicator layoutIfNeeded];
			}];
			
		} else {
			// we are moving forward
			
			if (selectedIndex + 1 >= numberOfTabs)
				return;
			
			float newX = offset.x - scrollViewWidth;
			
			UIView *selectedTab = (UIView*)tabs[selectedIndex];
			UIView *nexTab = (UIView*)tabs[selectedIndex + 1];
			
			float selectedOriginX = selectedTab.frame.origin.x;
			float nextTabWidth = nexTab.frame.size.width;
			
			float widthDiff = nextTabWidth - selectedTab.frame.size.width;
			
			float newOriginX = selectedOriginX + newX / scrollViewWidth * selectedTab.frame.size.width;
			tabSwipeView.indicatorLeftConst.constant = newOriginX;
			
			float newWidth = selectedTab.frame.size.width + newX / scrollViewWidth * widthDiff;
			tabSwipeView.indicatorWidthConst.constant = newWidth;
			
			[UIView animateWithDuration:0.01 animations:^{
				[tabSwipeView.indicator layoutIfNeeded];
			}];
			
		}
	}
	
	CGFloat indicatorMaxOriginX = scrollView.frame.size.width / 2 - tabSwipeView.indicator.frame.size.width / 2;
	
	CGFloat offsetX = tabSwipeView.indicator.frame.origin.x-indicatorMaxOriginX;
	
	if (offsetX < 0) offsetX = 0;
	if (offsetX > tabSwipeView.segmentController.frame.size.width-scrollViewWidth) offsetX = tabSwipeView.segmentController.frame.size.width-scrollViewWidth;
	
	[UIView animateWithDuration:isNotDragging ? 0.3 : 0.01 animations:^{
		tabSwipeView.tabScrollView.contentOffset = CGPointMake(offsetX, 0);
	}];
	
	previewsOffset = scrollView.contentOffset;
}

@end
