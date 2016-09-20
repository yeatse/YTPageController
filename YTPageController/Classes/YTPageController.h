//
//  YTPageController.h
//  YTPageController
//
//  Created by yeatse on 16/9/13.
//  Copyright © 2016年 yeatse. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YTPageTransitionContext, YTPageTransitionCoordinator, YTPageControllerDelegate, YTPageControllerDataSource;

@interface YTPageController : UIViewController

@property (nullable, nonatomic, weak) IBOutlet id<YTPageControllerDelegate> delegate;
@property (nullable, nonatomic, weak) IBOutlet id<YTPageControllerDataSource> dataSource;

// Ignored if `dataSource` is set.
@property (nullable, nonatomic, copy) NSArray<__kindof UIViewController*>* viewControllers;

@property (nonatomic) IBInspectable BOOL bounces;
@property (nonatomic) IBInspectable BOOL scrollEnabled;

@property (nonatomic, readonly) BOOL inTransition;
@property (nullable, nonatomic, readonly) id<YTPageTransitionCoordinator> pageCoordinator;

@property (nonatomic) NSInteger currentIndex;

- (void)setCurrentIndex:(NSInteger)currentIndex animated:(BOOL)animated;

- (void)reloadPages;

@end


@protocol YTPageTransitionCoordinator <NSObject>

/**
 Runs the specified animations in a view

 @param view       The view (or one of its ancestors) in which the specified animations take place.
 @param animation  A block containing the animations you want to perform.
 @param completion The block of code to execute after the transition finishes.
 */
- (void)animateAlongsidePagingInView:(UIView*)view animation:(void (^ _Nullable)(id<YTPageTransitionContext> _Nonnull context))animation completion:(void (^ _Nullable)(id<YTPageTransitionContext> _Nonnull context))completion;

@end


@protocol YTPageTransitionContext <NSObject>

@property (nonatomic, readonly) NSTimeInterval animationDuration;

@property (nonatomic, readonly) NSInteger fromIndex;
@property (nonatomic, readonly) NSInteger toIndex;

@property (nonatomic, readonly) CGFloat relativeOffset;

@property (nonatomic, readonly) BOOL isCanceled;

@end


@protocol YTPageControllerDataSource <NSObject>

// The number of view controllers in YTPageController
- (NSInteger)numberOfPagesInPageController:(YTPageController*)pageController;

- (UIViewController*)pageController:(YTPageController*)pageController pageAtIndex:(NSInteger)index;

@end


@protocol YTPageControllerDelegate <NSObject>

@optional

- (void)pageController:(YTPageController*)pageController willTransitionToIndex:(NSInteger)index;

- (void)pageController:(YTPageController*)pageController didUpdateTransition:(id<YTPageTransitionContext>)context;

- (void)pageController:(YTPageController *)pageController didEndTransition:(id<YTPageTransitionContext>)context;

@end

NS_ASSUME_NONNULL_END
