//
//  BetterSegmentedControlViewController.m
//  YTPageController
//
//  Created by yeatse on 2016/10/17.
//  Copyright © 2016年 Yeatse CC. All rights reserved.
//

#import "BetterSegmentedControlViewController.h"
#import <BetterSegmentedControl/BetterSegmentedControl-Swift.h>

@interface BetterSegmentedControlViewController ()<YTPageControllerDelegate>

@property (weak, nonatomic) IBOutlet BetterSegmentedControl *control;

@end

@implementation BetterSegmentedControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.control.titles = @[@"First", @"Second", @"Third"];
    self.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)controlValueChanged:(id)sender {
    NSInteger index = self.control.index;
    if (index != self.currentIndex) {
        [self setCurrentIndex:index animated:NO];
    }
}

#pragma mark - YTPageControllerDelegate

- (void)pageController:(YTPageController *)pageController willStartTransition:(id<YTPageTransitionContext>)context {
    [self.pageCoordinator animateAlongsidePagingInView:self.control animation:^(id<YTPageTransitionContext>  _Nonnull context) {
        self.control.userInteractionEnabled = NO;
        [self.control setWithIndex:[context toIndex] animated:YES error:nil];
    } completion:^(id<YTPageTransitionContext>  _Nonnull context) {
        self.control.userInteractionEnabled = YES;
        if ([context isCanceled]) {
            [self.control setWithIndex:[context fromIndex] animated:NO error:nil];
        }
    }];
}

@end
