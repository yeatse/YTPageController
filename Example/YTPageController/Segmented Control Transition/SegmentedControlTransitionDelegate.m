//
//  SegmentedControlTransitionDelegate.m
//  YTPageController
//
//  Created by Yang Chao on 16/9/20.
//  Copyright © 2016年 Yeatse CC. All rights reserved.
//

#import "SegmentedControlTransitionDelegate.h"

@interface SegmentedControlTransitionDelegate ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet YTPageController *pageController;

@end


@implementation SegmentedControlTransitionDelegate

- (void)pageController:(YTPageController *)pageController willStartTransition:(id<YTPageTransitionContext>)context {
    [pageController.pageCoordinator animateAlongsidePagingInView:self.segmentedControl animation:^(id<YTPageTransitionContext>  _Nonnull context) {
        self.segmentedControl.userInteractionEnabled = NO;
        self.segmentedControl.selectedSegmentIndex = [context toIndex];
    } completion:^(id<YTPageTransitionContext>  _Nonnull context) {
        if ([context isCanceled]) {
            self.segmentedControl.selectedSegmentIndex = [context fromIndex];
        }
        self.segmentedControl.userInteractionEnabled = YES;
    }];
}

- (IBAction)changeIndex:(id)sender {
    [self.pageController setCurrentIndex:[sender selectedSegmentIndex] animated:YES];
}

@end
