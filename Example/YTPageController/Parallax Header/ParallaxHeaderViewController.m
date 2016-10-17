//
//  ParallaxHeaderViewController.m
//  YTPageController
//
//  Created by Yang Chao on 2016/9/25.
//  Copyright © 2016年 Yeatse CC. All rights reserved.
//

#import "ParallaxHeaderViewController.h"
#import <YTPageController/YTPageController.h>

#import "ParallaxHeaderImageViewController.h"

@interface ParallaxHeaderViewController ()<UIScrollViewDelegate, YTPageControllerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *proxyScrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *containerScrollView;

@property (weak, nonatomic) IBOutlet UINavigationBar *segmentedControlNavigationBar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIView *headerView;

@property (nonatomic) YTPageController* pageController;
@property (nonatomic) ParallaxHeaderImageViewController* headerController;

@end

@implementation ParallaxHeaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _pageController = [self.storyboard instantiateViewControllerWithIdentifier:@"Page Controller"];
    _pageController.delegate = self;
    for (UITableViewController* vc in _pageController.viewControllers) {
        [vc.tableView addObserver:self forKeyPath:@"contentSize" options:kNilOptions context:NULL];
    }
    
    [self addChildViewController:_pageController];
    [_containerScrollView addSubview:_pageController.view];
    [_pageController didMoveToParentViewController:self];
    
    UIEdgeInsets insets = UIEdgeInsetsMake([self maximumTopInset], 0, 0, 0);
    _containerScrollView.contentInset = insets;
    _containerScrollView.scrollIndicatorInsets = insets;
}

- (void)dealloc {
    for (UITableViewController* vc in _pageController.viewControllers) {
        [vc.tableView removeObserver:self forKeyPath:@"contentSize"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Embed Header"]) {
        _headerController = segue.destinationViewController;
    }
}

#pragma mark - Content Geometry Handling

- (CGFloat)minimumTopInset {
    return _proxyScrollView.contentInset.top + CGRectGetHeight(_segmentedControlNavigationBar.frame);
}

- (CGFloat)maximumTopInset {
    return 300;
}

- (CGFloat)topInsetFromContentOffset:(CGFloat)offset {
    return MIN(MAX([self minimumTopInset], -offset), [self maximumTopInset]);
}

- (CGFloat)bottomInset {
    return _proxyScrollView.contentInset.bottom;
}

- (CGFloat)innerOffsetFromOuterOffset:(CGFloat)offset {
    if (offset < -[self maximumTopInset]) {
        return offset + [self maximumTopInset];
    } else if (offset > -[self minimumTopInset]) {
        return offset + [self minimumTopInset];
    } else {
        return 0;
    }
}

- (void)synchronizeTableViewAtIndex:(NSInteger)index {
    UITableViewController* vc = _pageController.viewControllers[index];
    vc.tableView.contentOffset = CGPointMake(0, [self innerOffsetFromOuterOffset:_containerScrollView.contentOffset.y]);
    _containerScrollView.contentSize = vc.tableView.contentSize;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat contentOffset = _containerScrollView.contentOffset.y;
    
    // Update insets of the outer scroll view
    UIEdgeInsets insets = UIEdgeInsetsMake([self topInsetFromContentOffset:contentOffset], 0, [self bottomInset], 0);
    if (contentOffset < -[self minimumTopInset]) {
        _containerScrollView.contentInset = UIEdgeInsetsMake([self maximumTopInset], 0, [self bottomInset], 0);
        _containerScrollView.scrollIndicatorInsets = insets;
    } else {
        _containerScrollView.contentInset = insets;
        _containerScrollView.scrollIndicatorInsets = insets;
    }
    
    // Update offset of the inner scroll view
    if (!_pageController.inTransition) {
        [self synchronizeTableViewAtIndex:_pageController.currentIndex];
    }
    
    // Update frame of the page controller view
    CGRect absoluteFrame = CGRectMake(0, insets.top, CGRectGetWidth(_containerScrollView.bounds), CGRectGetHeight(_containerScrollView.bounds) - insets.top - insets.bottom);
    _pageController.view.frame = [self.view convertRect:absoluteFrame toView:_containerScrollView];
    
    // Update frame of the segmented control
    CGFloat naviBarHeight = CGRectGetHeight(_segmentedControlNavigationBar.frame);
    _segmentedControlNavigationBar.frame = CGRectMake(0, insets.top - naviBarHeight, CGRectGetWidth(self.view.bounds), naviBarHeight);
    
    // Update frame of the header view
    _headerView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), insets.top);
}

#pragma mark - Event Handling

- (IBAction)changePageIndex:(id)sender {
    [_pageController setCurrentIndex:[sender selectedSegmentIndex] animated:YES];
    [_headerController setCurrentImageIndex:[sender selectedSegmentIndex]];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentSize"]) {
        [self.view setNeedsLayout];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view setNeedsLayout];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    scrollView.contentInset = UIEdgeInsetsMake([self maximumTopInset], 0, [self bottomInset], 0);
    return YES;
}

#pragma mark - YTPageControllerDelegate

- (void)pageController:(YTPageController *)pageController willStartTransition:(id<YTPageTransitionContext>)context {
    [self synchronizeTableViewAtIndex:[context toIndex]];
    
    [pageController.pageCoordinator animateAlongsidePagingInView:_segmentedControl animation:^(id<YTPageTransitionContext>  _Nonnull context) {
        _segmentedControl.selectedSegmentIndex = [context toIndex];
        _segmentedControl.userInteractionEnabled = NO;
    } completion:^(id<YTPageTransitionContext>  _Nonnull context) {
        if ([context isCanceled]) {
            _segmentedControl.selectedSegmentIndex = [context fromIndex];
        }
        _segmentedControl.userInteractionEnabled = YES;
    }];
    
    [pageController.pageCoordinator animateAlongsidePagingInView:_headerController.view animation:^(id<YTPageTransitionContext>  _Nonnull context) {
        _headerController.currentImageIndex = [context toIndex];
    } completion:^(id<YTPageTransitionContext>  _Nonnull context) {
        if ([context isCanceled]) {
            _headerController.currentImageIndex = [context fromIndex];
        }
    }];
}

@end
