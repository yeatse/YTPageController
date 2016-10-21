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

/**
 The delegate object.
 */
@property (nullable, nonatomic, weak) IBOutlet id<YTPageControllerDelegate> delegate;


/**
 The object that provides view controllers.
 
 If both viewControllers and dataSource are set, dataSource will take the priority.
 
 @note You must call -reloadPages after you change the data source.
 */
@property (nullable, nonatomic, weak) IBOutlet id<YTPageControllerDataSource> dataSource;


/**
 An array of the root view controllers displayed by the page controller.
 
 The order of the view controllers in the array corresponds to the display order in the page controller.
 
 If you provide a data source, this property will be ignored.
 
 @note You must call -reloadPages after you change the view controllers.
 */
@property (nullable, nonatomic, copy) NSArray<__kindof UIViewController *> *viewControllers;


/**
 A Boolean value that controls whether the inner scroll view bounces past the edge of content and back again.
 */
@property (nonatomic) IBInspectable BOOL bounces;


/**
 If the value of this property is YES, scrolling is enabled, otherwise disabled.
 */
@property (nonatomic) IBInspectable BOOL scrollEnabled;


/**
 A Boolean value indicating whether the controller is currently transitioning from one view controller to another.
 */
@property (nonatomic, readonly) BOOL inTransition;


/**
 Returns the active transition coordinator object which helps you run your own animations along with the page transitioning. This object is ephemeral and lasts for the duration of the transition animation.
 
 @note This property returns a valid coordinator only when the page scrolling is started by user gesture, otherwise returns nil.
 */
@property (nullable, nonatomic, readonly) id<YTPageTransitionCoordinator> pageCoordinator;


/**
 The index number identifying the current view controller displayed by the page controller.
 */
@property (nonatomic) NSInteger currentIndex;


/**
 The view controller currently displayed by the page controller, associated with currentIndex
 */
@property (nullable, nonatomic, readonly) __kindof UIViewController* currentViewController;


/**
 Sets the current index, in an animated way, if desired.
 
 @param currentIndex The index for the page controller to scroll into view.
 @param animated     Specify YES to animate the scrolling behavior or NO to set the visible view controller immediately.
 */
- (void)setCurrentIndex:(NSInteger)currentIndex animated:(BOOL)animated;


/**
 Reloads all of the view controllers for the page controller.
 
 You should not call this method in the middle of the transition process.
 */
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


/**
 An object that conforms to the YTPageTransitionContext protocol provides information about an in-progress page controller transition.
 */
@protocol YTPageTransitionContext <NSObject>

/**
 Return the duration near to the page transition duration. You can use this value to set the duration of your own animations along with the page transition.
 */
@property (nonatomic, readonly) NSTimeInterval animationDuration;

/**
 Returns the index at the beginning of the transition (and at the end of a canceled transition).
 */
@property (nonatomic, readonly) NSInteger fromIndex;

/**
 Returns the index at the end of the transition (also at the beginning of a canceled transition).
 */
@property (nonatomic, readonly) NSInteger toIndex;

/**
 Returns the view controller displayed by the page controller at the beginning of the transition (and at the end of canceled transition).
 */
@property (nullable, nonatomic, readonly) __kindof UIViewController* fromViewController;

/**
 Returns the view controller displayed by the page controller at the end of the transition (and at the beginning of a canceled transition).
 */
@property (nullable, nonatomic, readonly) __kindof UIViewController* toViewController;

/**
 The x value of the inner scroll view's contentOffset, divided by the width of the page controller.
 
 This property helps you update your own UI according to the transition progress. For example, if the page controller is transitioning from index 3 to index 4, this property will return 3 at the beginning, then return 3.1, 3.2... when the transition updates, and at last return 4.
 */
@property (nonatomic, readonly) CGFloat relativeOffset;

/**
 Returns YES if the transition is canceled.
 */
@property (nonatomic, readonly) BOOL isCanceled;

@end


@protocol YTPageControllerDataSource <NSObject>

/**
 Asks your data source object for the number of view controllers in the page controller.

 @param pageController The page controller requesting this information.
 
 @return The number of view controllers in the page controller.
 */
- (NSInteger)numberOfPagesInPageController:(YTPageController*)pageController;


/**
 Asks your data source object for the view controller at the index of the page controller.

 @param pageController The page controller requesting this information.
 @param index          The index that specifies the location of the view controller.

 @return The view controller at the index. The page controller will retain this view controller temporally and when the view controller moves out, if might be released later.
 */
- (UIViewController*)pageController:(YTPageController*)pageController pageAtIndex:(NSInteger)index;

@end


@protocol YTPageControllerDelegate <NSObject>

@optional

/**
 Tells the delegate that the transition is about to be started.
 
 A transition can be started by either user's gesture or calling -setCurrentIndex:animated:. This method will be called in both circumstances.

 @param pageController The page controller that is startting the transition.
 @param context        A context object containing the information of the transition process.
 */
- (void)pageController:(YTPageController *)pageController willStartTransition:(id<YTPageTransitionContext>)context;


/**
 Tells the delegate when the transition progress updates.
 
 @param pageController The page controller whose transition progress updates.
 @param context        A context object containing the information of the transition process.
 */
- (void)pageController:(YTPageController*)pageController didUpdateTransition:(id<YTPageTransitionContext>)context;


/**
 Tell the delegate that the transition has ended.

 @param pageController The page controller that finished the transition process.
 @param context        A context object containing the information of the transition process.
 */
- (void)pageController:(YTPageController *)pageController didEndTransition:(id<YTPageTransitionContext>)context;

/// Deprecated. Use -pageController:willStartTransition: instead.
- (void)pageController:(YTPageController*)pageController willTransitionToIndex:(NSInteger)index API_DEPRECATED_WITH_REPLACEMENT("-pageController:willStartTransition:", ios(8.0, 8.0));

@end

NS_ASSUME_NONNULL_END
