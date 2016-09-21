//
//  YTPageController.m
//  YTPageController
//
//  Created by yeatse on 16/9/13.
//  Copyright © 2016年 yeatse. All rights reserved.
//

#import "YTPageController.h"

#define YTPageLogEnabled 0

static NSTimeInterval const YTReferencedTransitionDuration = 1;
static NSString* const YTPageCollectionCellIdentifier = @"PageCollectionCell";


#pragma mark - Private Classes

@interface _YTPageTransitionContext : NSObject<YTPageTransitionContext>

@property (nonatomic) NSInteger fromIndex;
@property (nonatomic) NSInteger toIndex;
@property (nonatomic) BOOL isCanceled;
@property (nonatomic) CGFloat relativeOffset;
@property (nonatomic) NSTimeInterval animationDuration;

@end


@interface _YTPageTransitionCoordinator : NSObject<YTPageTransitionCoordinator>

- (instancetype)initWithContext:(id<YTPageTransitionContext>)context;

- (void)startTransition;

- (void)updateTransitionProgress:(CGFloat)progress;

- (void)finishTransition:(BOOL)complete;

@end


@interface _YTPageCollectionDataSource : NSObject<UICollectionViewDataSource>

+ (instancetype)dataSourceWithPageController:(YTPageController*)pageController;

@end


@interface _YTPageCollectionDelegate : NSObject<UICollectionViewDelegate>

+ (instancetype)delegateWithPageController:(YTPageController*)pageController;

@end


@interface YTPageCollectionViewCell : UICollectionViewCell

- (void)configureWithViewController:(UIViewController*)childVC parentViewController:(UIViewController*)parentVC;

@end


#pragma mark - YTPageController

@interface YTPageController ()<UICollectionViewDelegateFlowLayout>

@property (nonatomic) UICollectionViewFlowLayout* _collectionLayout;
@property (nonatomic) UICollectionView* _collectionView;
@property (nonatomic) _YTPageCollectionDataSource* _collectionViewDataSource;
@property (nonatomic) _YTPageCollectionDelegate* _collectionViewDelegate;

@property (nonatomic, readonly) _YTPageTransitionContext* _context;

@end


@implementation YTPageController {
    struct {
        BOOL willTransitionToIndex: 1;
        BOOL didUpdateTransition: 1;
        BOOL didEndTransition: 1;
    } _delegateRespondsTo;
    
    _YTPageTransitionContext* _context;
    _YTPageTransitionCoordinator* _coordinator;
}

@synthesize pageCoordinator = _coordinator;
@synthesize _context = _context;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _scrollEnabled = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _scrollEnabled = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add a proxy scrollview to eat the adjusted insets
    UIScrollView* proxyScrollView = [UIScrollView new];
    proxyScrollView.scrollEnabled = NO;
    proxyScrollView.hidden = YES;
    [self.view insertSubview:proxyScrollView atIndex:0];
    
    [self.view insertSubview:self._collectionView atIndex:1];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self._collectionLayout.itemSize = size;
    
    NSIndexPath* currIndexPath = [NSIndexPath indexPathForItem:self.currentIndex inSection:0];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self._collectionView scrollToItemAtIndexPath:currIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    } completion:nil];
}

- (void)setDelegate:(id<YTPageControllerDelegate>)delegate {
    _delegate = delegate;
    
    _delegateRespondsTo.willTransitionToIndex = [delegate respondsToSelector:@selector(pageController:willTransitionToIndex:)];
    _delegateRespondsTo.didUpdateTransition = [delegate respondsToSelector:@selector(pageController:didUpdateTransition:)];
    _delegateRespondsTo.didEndTransition = [delegate respondsToSelector:@selector(pageController:didEndTransition:)];
}

- (void)setBounces:(BOOL)bounces {
    _bounces = bounces;
    __collectionView.bounces = bounces;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    _scrollEnabled = scrollEnabled;
    __collectionView.scrollEnabled = scrollEnabled;
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    [self setCurrentIndex:currentIndex animated:NO];
}

- (void)setCurrentIndex:(NSInteger)currentIndex animated:(BOOL)animated {
    if (_inTransition) {
        return;
    }
    
    [self _startTransitionFromIndex:_currentIndex toIndex:currentIndex animated:animated];
    
    _currentIndex = currentIndex;
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:currentIndex inSection:0];
    [self._collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
    
    if (!animated) {
        [self _finishTransition];
    }
}

- (void)reloadPages {
    [self._collectionView reloadData];
}

#pragma mark - `viewControllers` property support

- (NSInteger)_numberOfViewControllers {
    if (_dataSource) {
        return [_dataSource numberOfPagesInPageController:self];
    } else {
        return _viewControllers.count;
    }
}

- (UIViewController*)_viewControllerAtIndex:(NSInteger)index {
    if (_dataSource) {
        return [_dataSource pageController:self pageAtIndex:index];
    } else {
        return _viewControllers[index];
    }
}

#pragma mark - State Handling

- (void)_startTransitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex animated:(BOOL)animated {
    if (fromIndex == toIndex) {
        return;
    }
    _inTransition = YES;
    
    _context = [_YTPageTransitionContext new];
    _context.fromIndex = fromIndex;
    _context.toIndex = toIndex;
    _context.animationDuration = animated ? YTReferencedTransitionDuration : 0;
    
    if (animated) {
        _coordinator = [[_YTPageTransitionCoordinator alloc] initWithContext:_context];
    } else {
        _coordinator = nil;
    }
    
    if (_delegateRespondsTo.willTransitionToIndex) {
        [self.delegate pageController:self willTransitionToIndex:toIndex];
    }
    
    [_coordinator startTransition];
}

- (void)_updateTransitionWithOffset:(CGFloat)relativeOffset {
    _context.relativeOffset = relativeOffset;
    
    CGFloat progress = (relativeOffset - (CGFloat)_context.fromIndex) / (CGFloat)(_context.toIndex - _context.fromIndex);
    progress = MIN(MAX(0, progress), 1);
    
    [_coordinator updateTransitionProgress:progress];
    
    if (_delegateRespondsTo.didUpdateTransition) {
        [self.delegate pageController:self didUpdateTransition:_context];
    }
}

- (void)_finishTransition {
    BOOL shouldComplete = ABS(_context.relativeOffset - (CGFloat)_context.fromIndex) > ABS(_context.relativeOffset - (CGFloat)_context.toIndex);
    [self _finishTransition:shouldComplete];
}

- (void)_finishTransition:(BOOL)complete {
    if (complete) {
        [_coordinator updateTransitionProgress:1];
        _currentIndex = _context.toIndex;
    } else {
        [_coordinator updateTransitionProgress:0];
        _context.isCanceled = YES;
    }
    
    [_coordinator finishTransition:complete];
    
    _inTransition = NO;
    
    if (_delegateRespondsTo.didEndTransition) {
        [self.delegate pageController:self didEndTransition:_context];
    }
    
    _context = nil;
}

#pragma mark - Getters

- (UICollectionViewFlowLayout *)_collectionLayout {
    if (!__collectionLayout) {
        __collectionLayout = [UICollectionViewFlowLayout new];
        __collectionLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        __collectionLayout.itemSize = self.view.bounds.size;
        __collectionLayout.minimumLineSpacing = 0;
        __collectionLayout.minimumInteritemSpacing = 0;
    }
    return __collectionLayout;
}

- (UICollectionView *)_collectionView {
    if (!__collectionView) {
        __collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self._collectionLayout];
        __collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        __collectionView.backgroundColor = [UIColor clearColor];
        __collectionView.showsHorizontalScrollIndicator = NO;
        __collectionView.pagingEnabled = YES;
        __collectionView.scrollEnabled = self.scrollEnabled;
        __collectionView.bounces = self.bounces;
        __collectionView.dataSource = self._collectionViewDataSource;
        __collectionView.delegate = self._collectionViewDelegate;
        [__collectionView registerClass:[YTPageCollectionViewCell class] forCellWithReuseIdentifier:YTPageCollectionCellIdentifier];
    }
    return __collectionView;
}

- (_YTPageCollectionDataSource *)_collectionViewDataSource {
    if (!__collectionViewDataSource) {
        __collectionViewDataSource = [_YTPageCollectionDataSource dataSourceWithPageController:self];
    }
    return __collectionViewDataSource;
}

- (_YTPageCollectionDelegate *)_collectionViewDelegate {
    if (!__collectionViewDelegate) {
        __collectionViewDelegate = [_YTPageCollectionDelegate delegateWithPageController:self];
    }
    return __collectionViewDelegate;
}

@end


#pragma mark - Private Classes Implementation

@implementation _YTPageTransitionContext

@end


@implementation _YTPageTransitionCoordinator {
    id<YTPageTransitionContext> _context;
    
    NSMutableArray* _animatingViews;
    NSMutableArray* _animationBlocks;
    NSMutableArray* _completionBlocks;
}

- (instancetype)initWithContext:(id<YTPageTransitionContext>)context {
    self = [super init];
    if (self) {
        _context = context;
        
        _animatingViews = [NSMutableArray array];
        _animationBlocks = [NSMutableArray array];
        _completionBlocks = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    for (UIView* view in _animatingViews) {
        view.layer.speed = 1;
        view.layer.timeOffset = 0;
        [self restoreSublayerStateOfLayer:view.layer];
    }
}

- (void)restoreSublayerStateOfLayer:(CALayer*)layer {
    // Use stack instead of recursion to keep from stack overflow.
    NSMutableArray<CALayer*>* layerStack = [NSMutableArray arrayWithObject:layer];
    while (layerStack.count > 0) {
        CALayer* layer = layerStack.lastObject;
        [layer removeAllAnimations]; // Remove all the animations on the fly
        
        [layerStack removeLastObject];
        if (layer.sublayers.count > 0) {
            [layerStack addObjectsFromArray:layer.sublayers];
        }
    }
}

- (void)animateAlongsidePagingInView:(UIView *)view animation:(void (^)(id<YTPageTransitionContext> _Nonnull))animation completion:(void (^)(id<YTPageTransitionContext> _Nonnull))completion {
    
    if (![_animatingViews containsObject:view]) {
        [_animatingViews addObject:view];
    }
    
    if (animation) {
        [_animationBlocks addObject:animation];
    }
    
    if (completion) {
        [_completionBlocks addObject:completion];
    }
}

- (void)startTransition {
    for (UIView* view in _animatingViews) {
        view.layer.speed = 0;
        view.layer.timeOffset = 0;
    }
    if (_animationBlocks.count > 0) {
        CADisplayLink* link = [CADisplayLink displayLinkWithTarget:self selector:@selector(startAnimationsAfterScreenUpdate:)];
        [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)startAnimationsAfterScreenUpdate:(CADisplayLink*)link {
    [link invalidate];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_animationBlocks.count) {
            [UIView animateWithDuration:[_context animationDuration] animations:^{
                for (void(^block)() in _animationBlocks) {
                    block(_context);
                }
            }];
            [_animationBlocks removeAllObjects];
        }
    });
}

- (void)updateTransitionProgress:(CGFloat)progress {
    for (UIView* view in _animatingViews) {
        if (view.layer.speed != 0) {
            view.layer.speed = 0;
        }
        view.layer.timeOffset = progress * [_context animationDuration];
    }
    if (_animationBlocks.count > 0) {
        CADisplayLink* link = [CADisplayLink displayLinkWithTarget:self selector:@selector(startAnimationsAfterScreenUpdate:)];
        [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)finishTransition:(BOOL)complete {
    for (UIView* view in _animatingViews) {
        view.layer.speed = 1;
        view.layer.timeOffset = 0;
    }
    for (void(^block)() in _completionBlocks) {
        block(_context);
    }
}

@end


@implementation _YTPageCollectionDataSource {
    YTPageController* __weak _controller;
}

+ (instancetype)dataSourceWithPageController:(YTPageController *)pageController {
    _YTPageCollectionDataSource* dataSource = [[self alloc] init];
    if (dataSource) {
        dataSource->_controller = pageController;
    }
    return dataSource;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_controller _numberOfViewControllers];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YTPageCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:YTPageCollectionCellIdentifier forIndexPath:indexPath];
    UIViewController* page = [_controller _viewControllerAtIndex:indexPath.item];
    [cell configureWithViewController:page parentViewController:_controller];
    return cell;
}

@end


@implementation _YTPageCollectionDelegate {
    YTPageController* __weak _controller;
    NSInteger _draggingTargetIndex;
}

+ (instancetype)delegateWithPageController:(YTPageController *)pageController {
    _YTPageCollectionDelegate* delegate = [[self alloc] init];
    if (delegate) {
        delegate->_controller = pageController;
    }
    return delegate;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    // Caused by setCurrentIndex:animated:
    if (_controller.inTransition) {
        [_controller _finishTransition];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    _draggingTargetIndex = round(targetContentOffset->x / CGRectGetWidth(scrollView.bounds));
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate && _controller.inTransition) {
        [_controller _finishTransition];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (_controller.inTransition) {
        [_controller _finishTransition];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    YTPageController* ctrl = _controller;
    if (!ctrl) { return; }
    
    CGFloat relativeOffset = scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds);
    if (!ctrl.inTransition) { // Transition not started
        if (!scrollView.dragging) {
            return; // Ignore scrolling which not began by dragging
        }
        
        CGFloat startOffset = (CGFloat)ctrl.currentIndex;
        if (ABS(relativeOffset - startOffset) > DBL_EPSILON) {
            // Start transition
            NSInteger newIndex = (NSInteger)(relativeOffset > startOffset ? ceil(relativeOffset) : floor(relativeOffset));
            if (newIndex >= 0 && newIndex < [ctrl _numberOfViewControllers]) {
                [ctrl _startTransitionFromIndex:ctrl.currentIndex toIndex:newIndex animated:YES];
                [ctrl _updateTransitionWithOffset:relativeOffset];
            }
        }
    } else { // Transition is in progress
        NSInteger fromIndex = ctrl._context.fromIndex;
        NSInteger toIndex = ctrl._context.toIndex;
        NSInteger newIndex = relativeOffset > (CGFloat)ctrl.currentIndex ? ceil(relativeOffset) : floor(relativeOffset);
        
        CGFloat progress = (relativeOffset - (CGFloat)fromIndex) / (CGFloat)(toIndex - fromIndex);
        BOOL overDragging = NO;
        if (scrollView.dragging && (progress < -DBL_EPSILON || progress - 1 > DBL_EPSILON)) {
            if (scrollView.tracking) {
                overDragging = YES;
            } else if (ABS(newIndex - ctrl.currentIndex) > 1) {
                // When scrolling fast the `scrollViewWillEndDragging:withVelocity:targetContentOffset:` may be not called
                // So we force the index to update
                overDragging = YES;
            } else if (progress > 1) {
                // Ignore progress overrange when scroll view is bouncing back
                overDragging = fromIndex < toIndex ? _draggingTargetIndex > toIndex : _draggingTargetIndex < toIndex;
            } else if (progress < 0) {
                overDragging = fromIndex < toIndex ? fromIndex > _draggingTargetIndex : fromIndex < _draggingTargetIndex;
            }
#if YTPageLogEnabled
            NSLog(@"over dragging test: tracking = %zd, from = %zd, to = %zd, target = %zd, overdragging = %d", scrollView.tracking, fromIndex, toIndex, _draggingTargetIndex, overDragging);
#endif
        }
        
        if (overDragging) {
            if (newIndex >= 0 && newIndex < [ctrl _numberOfViewControllers]) {
                // Restart a new transition if progress not within (0, 1)
                [ctrl _finishTransition];
                [ctrl _startTransitionFromIndex:ctrl.currentIndex toIndex:newIndex animated:YES];
            }
        }
        
        [ctrl _updateTransitionWithOffset:relativeOffset];
    }
}

@end


@implementation YTPageCollectionViewCell {
    UIViewController* _controller;
}

- (void)configureWithViewController:(UIViewController *)childVC parentViewController:(UIViewController *)parentVC {
    [self cleanUpChildViewController];
    
    [parentVC addChildViewController:childVC];
    [self.contentView addSubview:childVC.view];
    childVC.view.frame = self.contentView.bounds;
    [childVC didMoveToParentViewController:parentVC];
    
    _controller = childVC;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _controller.view.frame = self.contentView.bounds;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self cleanUpChildViewController];
}

- (void)cleanUpChildViewController {
    [_controller willMoveToParentViewController:nil];
    [_controller.view removeFromSuperview];
    [_controller removeFromParentViewController];
    _controller = nil;
}

@end
