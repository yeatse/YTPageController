# YTPageController

[![CI Status](http://img.shields.io/travis/Yeatse CC/YTPageController.svg?style=flat)](https://travis-ci.org/Yeatse CC/YTPageController)
[![Version](https://img.shields.io/cocoapods/v/YTPageController.svg?style=flat)](http://cocoapods.org/pods/YTPageController)
[![License](https://img.shields.io/cocoapods/l/YTPageController.svg?style=flat)](http://cocoapods.org/pods/YTPageController)
[![Platform](https://img.shields.io/cocoapods/p/YTPageController.svg?style=flat)](http://cocoapods.org/pods/YTPageController)

Yet another drop-in replacement of `UIPageViewController`, inspired by Apple's offical Music app.

## What problem does YTPageController try to resolve?

YTPageController introduces a general solution to achieve a smooth transition when user scrolls between view controllers, just as what Apple did in their Music app:

![](/snapshot0.gif)

To implement this effect, just add these lines of code in your `YTPageControllerDelegate`:

```objectivec
- (void)pageController:(YTPageController *)pageController willTransitionToIndex:(NSInteger)index {
    [pageController.pageCoordinator animateAlongsidePagingInView:self.segmentedControl animation:^(id<YTPageTransitionContext>  _Nonnull context) {
        // Update your segmented control according to the information contained in YTPageTransitionContext
        self.segmentedControl.selectedSegmentIndex = [context toIndex];
    } completion:^(id<YTPageTransitionContext>  _Nonnull context) {
        if ([context isCanceled]) {
            // Revert to original state if transition canceled
            self.segmentedControl.selectedSegmentIndex = [context fromIndex];
        }
    }];
}
```

The key idea to control the percent of its animation is to set the CALayer's `speed` property to 0, and then update the `timeOffset` value according to UIScrollView's `contentOffset`. In addition to `UISegmentedControl`, you can also animate `UITabBar` or any `UIView` subclass you like. Refer to the example project for detailed information.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS 8.0 or above.
May be working from iOS 6.0, but I didn't test it.

## Installation

YTPageController is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod "YTPageController"
```

## Author

Yeatse CC, iyeatse@gmail.com

## License

YTPageController is available under the MIT license. See the LICENSE file for more info.



