//
//  YTPageController.m
//  YTPageController
//
//  Created by yeatse on 16/9/13.
//  Copyright © 2016年 yeatse. All rights reserved.
//

#import "YTPageController.h"

#ifndef YTPageLogEnabled
#define YTPageLogEnabled 0
#endif

static NSTimeInterval const YTReferencedTransitionDuration = 1;
static NSString* const YTPageCollectionCellIdentifier = @"PageCollectionCell";

typedef NS_ENUM(NSInteger, YTPageTransitionStartReason) {
    YTPageTransitionStartedByUser,
    YTPageTransitionStartedProgrammically
};

#pragma mark - Private Classes

@interface _YTPageTransitionContext : NSObject<YTPageTransitionContext>

@property (nonatomic) NSInteger fromIndex;
@property (nonatomic) NSInteger toIndex;

@property (nonatomic) __kindof UIViewController* fromViewController;
@property (nonatomic) __kindof UIViewController* toViewController;

@property (nonatomic) BOOL isCanceled;

@property (nonatomic) CGFloat relativeOffset;

@property (nonatomic) NSTimeInterval animationDuration;

@property (nonatomic) YTPageTransitionStartReason startReason;

@end


@interface _YTPageTransitionCoordinator : NSObject<YTPageTransitionCoordinator>

- (instancetype)initWithContext:(id<YTPageTransitionContext>)context;

- (void)startTransition;

- (void)updateTransitionProgress:(CGFloat)progress;

- (void)finishTransition:(BOOL)complete;

@end


@interface _YTPageCollectionDataSource : NSObject<UICollectionViewDataSource>

- (instancetype)initWithPageController:(YTPageController*)pageController;

- (void)refreshCache;

- (NSInteger)numberOfViewControllers;

- (__kindof UIViewController*)viewControllerAtIndex:(NSInteger)index;

@end


@interface _YTPageCollectionDelegate : NSObject<UICollectionViewDelegate>

- (instancetype)initWithPageController:(YTPageController*)pageController;

@end


@interface YTPageCollectionViewCell : UICollectionViewCell

@property (nonatomic) NSIndexPath* indexPath;

- (void)configureWithViewController:(UIViewController*)childVC parentViewController:(UIViewController*)parentVC;

- (BOOL)isOwnerOfViewController:(UIViewController*)viewController;

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
        BOOL willStartTransition: 1;
        BOOL willTransitionToIndex: 1;
        BOOL didUpdateTransition: 1;
        BOOL didEndTransition: 1;
    } _delegateRespondsTo;
    
    _YTPageTransitionContext* _context;
    _YTPageTransitionCoordinator* _coordinator;
}

@synthesize _collectionLayout = _collectionLayout;
@synthesize _collectionView = _collectionView;
@synthesize _collectionViewDataSource = _collectionViewDataSource;
@synthesize _collectionViewDelegate = _collectionViewDelegate;

@synthesize _context = _context;
@synthesize pageCoordinator = _coordinator;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit {
    _scrollEnabled = YES;
    _currentIndex = -1;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add a proxy scrollview to eat the adjusted insets
    UIScrollView* proxyScrollView = [UIScrollView new];
    proxyScrollView.scrollEnabled = NO;
    proxyScrollView.hidden = YES;
    proxyScrollView.scrollsToTop = NO;
    [self.view insertSubview:proxyScrollView atIndex:0];
    [self.view insertSubview:self._collectionView atIndex:1];
    
    if (self._collectionViewDataSource.numberOfViewControllers > 0) {
        _currentIndex = 0;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self._collectionLayout.itemSize = self.view.bounds.size;
    self._collectionView.frame = self.view.bounds;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    NSIndexPath* currIndexPath = [NSIndexPath indexPathForItem:self.currentIndex inSection:0];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self._collectionView scrollToItemAtIndexPath:currIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    } completion:nil];
}

- (void)setDelegate:(id<YTPageControllerDelegate>)delegate {
    _delegate = delegate;
    
    _delegateRespondsTo.willStartTransition = [delegate respondsToSelector:@selector(pageController:willStartTransition:)];
    _delegateRespondsTo.willTransitionToIndex = [delegate respondsToSelector:@selector(pageController:willTransitionToIndex:)];
    _delegateRespondsTo.didUpdateTransition = [delegate respondsToSelector:@selector(pageController:didUpdateTransition:)];
    _delegateRespondsTo.didEndTransition = [delegate respondsToSelector:@selector(pageController:didEndTransition:)];
}

- (void)setBounces:(BOOL)bounces {
    _bounces = bounces;
    _collectionView.bounces = bounces;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    _scrollEnabled = scrollEnabled;
    _collectionView.scrollEnabled = scrollEnabled;
}

- (UIViewController *)currentViewController {
    if (_currentIndex < 0 || _currentIndex >= self._collectionViewDataSource.numberOfViewControllers) {
        return nil;
    } else {
        return [self._collectionViewDataSource viewControllerAtIndex:_currentIndex];
    }
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    [self setCurrentIndex:currentIndex animated:NO];
}

- (void)setCurrentIndex:(NSInteger)currentIndex animated:(BOOL)animated {
    if (_inTransition) {
        // If previous transition was started by user, cancel it; otherwise finish it.
        BOOL shouldComplete = (_context.startReason == YTPageTransitionStartedProgrammically);
        [self _finishTransition:shouldComplete];
    }
    
    [self _startTransitionToIndex:currentIndex reason:YTPageTransitionStartedProgrammically];
    
    _currentIndex = currentIndex;
    
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:currentIndex inSection:0];
    [self._collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
    
    if (!animated) {
        [self _finishTransition:YES];
    }
}

- (void)reloadPages {
    [self._collectionViewDataSource refreshCache];
    [self._collectionView reloadData];
    
    if (!_inTransition) {
        NSInteger pageCount = self._collectionViewDataSource.numberOfViewControllers;
        if (pageCount <= 0) {
            _currentIndex = -1;
        } else {
            _currentIndex = MIN(MAX(0, _currentIndex), pageCount - 1);
        }
    } else {
        // There may be some bugs when reload pages during paging. I'm still working on resolving it.
    }
    
}

#pragma mark - State Handling

- (void)_startTransitionToIndex:(NSInteger)toIndex reason:(YTPageTransitionStartReason)reason {
    if (_currentIndex == toIndex) {
        return;
    }
    
    _inTransition = YES;
    
    _context = [_YTPageTransitionContext new];
    _context.fromIndex = _currentIndex;
    _context.toIndex = toIndex;
    _context.startReason = reason;
    
    NSInteger pageCount = self._collectionViewDataSource.numberOfViewControllers;
    if (_currentIndex >= 0 && _currentIndex < pageCount) {
        _context.fromViewController = [self._collectionViewDataSource viewControllerAtIndex:_currentIndex];
    }
    if (toIndex >= 0 && toIndex < pageCount) {
        _context.toViewController = [self._collectionViewDataSource viewControllerAtIndex:toIndex];
    }
    
    if (reason == YTPageTransitionStartedByUser) {
        _context.animationDuration = YTReferencedTransitionDuration;
        _coordinator = [[_YTPageTransitionCoordinator alloc] initWithContext:_context];
    } else {
        _context.animationDuration = 0;
        _coordinator = nil;
    }
    
    if (_delegateRespondsTo.willStartTransition) {
        [self.delegate pageController:self willStartTransition:_context];
    } else if (_delegateRespondsTo.willTransitionToIndex) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.delegate pageController:self willTransitionToIndex:toIndex];
#pragma clang diagnostic pop
    }
    
    [_coordinator startTransition];
}

- (void)_updateTransitionWithOffset:(CGFloat)relativeOffset {
    _context.relativeOffset = relativeOffset;
    
    if (_context.startReason == YTPageTransitionStartedByUser) {
        CGFloat progress = (relativeOffset - (CGFloat)_context.fromIndex) / (CGFloat)(_context.toIndex - _context.fromIndex);
        progress = MIN(MAX(0, progress), 1);
        [_coordinator updateTransitionProgress:progress];
    }
    
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
    _coordinator = nil;
}

#pragma mark - Getters

- (UICollectionViewFlowLayout *)_collectionLayout {
    if (!_collectionLayout) {
        _collectionLayout = [UICollectionViewFlowLayout new];
        _collectionLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionLayout.itemSize = self.view.bounds.size;
        _collectionLayout.minimumLineSpacing = 0;
        _collectionLayout.minimumInteritemSpacing = 0;
    }
    return _collectionLayout;
}

- (UICollectionView *)_collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self._collectionLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.pagingEnabled = YES;
        _collectionView.scrollsToTop = NO;
        _collectionView.scrollEnabled = self.scrollEnabled;
        _collectionView.bounces = self.bounces;
        _collectionView.dataSource = self._collectionViewDataSource;
        _collectionView.delegate = self._collectionViewDelegate;
        [_collectionView registerClass:[YTPageCollectionViewCell class] forCellWithReuseIdentifier:YTPageCollectionCellIdentifier];
    }
    return _collectionView;
}

- (_YTPageCollectionDataSource *)_collectionViewDataSource {
    if (!_collectionViewDataSource) {
        _collectionViewDataSource = [[_YTPageCollectionDataSource alloc] initWithPageController:self];
    }
    return _collectionViewDataSource;
}

- (_YTPageCollectionDelegate *)_collectionViewDelegate {
    if (!_collectionViewDelegate) {
        _collectionViewDelegate = [[_YTPageCollectionDelegate alloc] initWithPageController:self];
    }
    return _collectionViewDelegate;
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
    // release all retained blocks
    [_animationBlocks removeAllObjects];
    [_completionBlocks removeAllObjects];
}

@end


@implementation _YTPageCollectionDataSource {
    YTPageController* __weak _controller;
    NSMutableDictionary<NSNumber*, UIViewController*>* _controllerCache;
}

- (instancetype)initWithPageController:(YTPageController *)pageController {
    self = [super init];
    if (self) {
        _controller = pageController;
        _controllerCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)refreshCache {
    for (UIViewController* controller in _controllerCache.allValues) {
        [controller willMoveToParentViewController:nil];
        [controller.view removeFromSuperview];
        [controller removeFromParentViewController];
    }
    [_controllerCache removeAllObjects];
}

- (NSInteger)numberOfViewControllers {
    YTPageController* controller = _controller;
    if (controller.dataSource) {
        return [controller.dataSource numberOfPagesInPageController:controller];
    } else {
        return controller.viewControllers.count;
    }
}

- (UIViewController *)viewControllerAtIndex:(NSInteger)index {
    UIViewController* result = _controllerCache[@(index)];
    if (result == nil) {
        YTPageController* controller = _controller;
        if (controller.dataSource) {
            result = [controller.dataSource pageController:controller pageAtIndex:index];
        } else {
            result = controller.viewControllers[index];
        }
        _controllerCache[@(index)] = result;
    }
    return result;
}

- (void)removeViewControllerAtIndex:(NSInteger)index {
    UIViewController* controller = _controllerCache[@(index)];
    if (controller) {
        [controller willMoveToParentViewController:nil];
        [controller.view removeFromSuperview];
        [controller removeFromParentViewController];
        
        [_controllerCache removeObjectForKey:@(index)];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.numberOfViewControllers;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YTPageCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:YTPageCollectionCellIdentifier forIndexPath:indexPath];
    
    if (cell.indexPath) {
        // Remove the old controller attached with the reused cell, if any.
        UIViewController* controller = _controllerCache[@(cell.indexPath.item)];
        if (controller != nil && [cell isOwnerOfViewController:controller]) {
            [self removeViewControllerAtIndex:cell.indexPath.item];
        }
    }
    
    UIViewController* page = [self viewControllerAtIndex:indexPath.item];
    [cell configureWithViewController:page parentViewController:_controller];
    cell.indexPath = indexPath;
    
    return cell;
}

@end


@implementation _YTPageCollectionDelegate {
    YTPageController* __weak _controller;
    NSInteger _draggingTargetIndex;
}

- (instancetype)initWithPageController:(YTPageController *)pageController {
    self = [super init];
    if (self) {
        _controller = pageController;
    }
    return self;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    // Caused by setCurrentIndex:animated:
    if (_controller.inTransition) {
        [_controller _finishTransition:YES];
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
            if (newIndex >= 0 && newIndex < ctrl._collectionViewDataSource.numberOfViewControllers) {
                if (ABS(ctrl.currentIndex - newIndex) > 1) { // Sometimes the `currentIndex` will be out of sync
                    [ctrl _startTransitionToIndex:(ctrl.currentIndex > newIndex ? newIndex + 1 : newIndex - 1) reason:YTPageTransitionStartedProgrammically];
                    [ctrl _finishTransition:YES];
                }
                [ctrl _startTransitionToIndex:newIndex reason:YTPageTransitionStartedByUser];
                [ctrl _updateTransitionWithOffset:relativeOffset];
            }
        }
    } else { // Transition is in progress
        NSInteger fromIndex = ctrl._context.fromIndex;
        NSInteger toIndex = ctrl._context.toIndex;
        NSInteger newIndex = relativeOffset > (CGFloat)ctrl.currentIndex ? ceil(relativeOffset) : floor(relativeOffset);
        
        CGFloat progress = (relativeOffset - (CGFloat)fromIndex) / (CGFloat)(toIndex - fromIndex);
        BOOL overDragging = NO;
        if (progress < -DBL_EPSILON || progress - 1 > DBL_EPSILON) {
            if (scrollView.tracking) {
                overDragging = YES;
            } else if (ABS(newIndex - ctrl.currentIndex) > 2) {
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
            if (newIndex >= 0 && newIndex < ctrl._collectionViewDataSource.numberOfViewControllers) {
                // Restart a new transition if progress not within (0, 1)
                [ctrl _finishTransition];
                [ctrl _startTransitionToIndex:newIndex reason:YTPageTransitionStartedByUser];
            }
        }
        
        [ctrl _updateTransitionWithOffset:relativeOffset];
    }
}

@end


@implementation YTPageCollectionViewCell

- (void)configureWithViewController:(UIViewController *)childVC parentViewController:(UIViewController *)parentVC {
    [parentVC addChildViewController:childVC];
    [self.contentView addSubview:childVC.view];
    childVC.view.frame = self.contentView.bounds;
    childVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [childVC didMoveToParentViewController:parentVC];
}

- (void)prepareForReuse {
    [super prepareForReuse];
}

- (BOOL)isOwnerOfViewController:(UIViewController *)viewController {
    return viewController.view.superview == self.contentView;
}

@end
