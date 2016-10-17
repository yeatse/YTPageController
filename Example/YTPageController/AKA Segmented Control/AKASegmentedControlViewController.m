//
//  AKASegmentedControlViewController.m
//  YTPageController
//
//  Created by yeatse on 2016/10/17.
//  Copyright © 2016年 Yeatse CC. All rights reserved.
//

#import "AKASegmentedControlViewController.h"
#import <AKASegmentedControl/AKASegmentedControl.h>

@interface AKASegmentedControlViewController ()<YTPageControllerDelegate>

@property (weak, nonatomic) IBOutlet AKASegmentedControl *control;

@end

@implementation AKASegmentedControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;
    self.control.segmentedControlMode = AKASegmentedControlModeSticky;
    [self.control setSelectedIndex:0];
    [self setupSegmentedControl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Copied from AKASegmentedControl Example
- (void)setupSegmentedControl {
    UIImage *backgroundImage = [[UIImage imageNamed:@"segmented-bg.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)];
    [self.control setBackgroundImage:backgroundImage];
    [self.control setContentEdgeInsets:UIEdgeInsetsMake(2.0, 2.0, 3.0, 2.0)];
    [self.control setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
    
    [self.control setSeparatorImage:[UIImage imageNamed:@"segmented-separator.png"]];
    
    UIImage *buttonBackgroundImagePressedLeft = [[UIImage imageNamed:@"segmented-bg-pressed-left.png"]
                                                 resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 4.0, 0.0, 1.0)];
    UIImage *buttonBackgroundImagePressedCenter = [[UIImage imageNamed:@"segmented-bg-pressed-center.png"]
                                                   resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 4.0, 0.0, 1.0)];
    UIImage *buttonBackgroundImagePressedRight = [[UIImage imageNamed:@"segmented-bg-pressed-right.png"]
                                                  resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 1.0, 0.0, 4.0)];
    
    // Button 1
    UIButton *buttonSocial = [[UIButton alloc] init];
    UIImage *buttonSocialImageNormal = [UIImage imageNamed:@"social-icon.png"];
    
    [buttonSocial setImageEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 5.0)];
    [buttonSocial setBackgroundImage:buttonBackgroundImagePressedLeft forState:UIControlStateHighlighted];
    [buttonSocial setBackgroundImage:buttonBackgroundImagePressedLeft forState:UIControlStateSelected];
    [buttonSocial setBackgroundImage:buttonBackgroundImagePressedLeft forState:(UIControlStateHighlighted|UIControlStateSelected)];
    [buttonSocial setImage:buttonSocialImageNormal forState:UIControlStateNormal];
    [buttonSocial setImage:buttonSocialImageNormal forState:UIControlStateSelected];
    [buttonSocial setImage:buttonSocialImageNormal forState:UIControlStateHighlighted];
    [buttonSocial setImage:buttonSocialImageNormal forState:(UIControlStateHighlighted|UIControlStateSelected)];
    
    // Button 2
    UIButton *buttonStar = [[UIButton alloc] init];
    UIImage *buttonStarImageNormal = [UIImage imageNamed:@"star-icon.png"];
    
    [buttonStar setBackgroundImage:buttonBackgroundImagePressedCenter forState:UIControlStateHighlighted];
    [buttonStar setBackgroundImage:buttonBackgroundImagePressedCenter forState:UIControlStateSelected];
    [buttonStar setBackgroundImage:buttonBackgroundImagePressedCenter forState:(UIControlStateHighlighted|UIControlStateSelected)];
    [buttonStar setImage:buttonStarImageNormal forState:UIControlStateNormal];
    [buttonStar setImage:buttonStarImageNormal forState:UIControlStateSelected];
    [buttonStar setImage:buttonStarImageNormal forState:UIControlStateHighlighted];
    [buttonStar setImage:buttonStarImageNormal forState:(UIControlStateHighlighted|UIControlStateSelected)];
    
    // Button 3
    UIButton *buttonSettings = [[UIButton alloc] init];
    UIImage *buttonSettingsImageNormal = [UIImage imageNamed:@"settings-icon.png"];
    
    [buttonSettings setBackgroundImage:buttonBackgroundImagePressedRight forState:UIControlStateHighlighted];
    [buttonSettings setBackgroundImage:buttonBackgroundImagePressedRight forState:UIControlStateSelected];
    [buttonSettings setBackgroundImage:buttonBackgroundImagePressedRight forState:(UIControlStateHighlighted|UIControlStateSelected)];
    [buttonSettings setImage:buttonSettingsImageNormal forState:UIControlStateNormal];
    [buttonSettings setImage:buttonSettingsImageNormal forState:UIControlStateSelected];
    [buttonSettings setImage:buttonSettingsImageNormal forState:UIControlStateHighlighted];
    [buttonSettings setImage:buttonSettingsImageNormal forState:(UIControlStateHighlighted|UIControlStateSelected)];
    
    [self.control setButtonsArray:@[buttonSocial, buttonStar, buttonSettings]];
}

- (IBAction)controlValueChanged:(id)sender {
    NSInteger index = self.control.selectedIndexes.firstIndex;
    if (index != self.currentIndex) {
        [self setCurrentIndex:index animated:NO];
    }
}

#pragma mark - YTPageControllerDelegate

- (void)pageController:(YTPageController *)pageController willStartTransition:(id<YTPageTransitionContext>)context {
    [pageController.pageCoordinator animateAlongsidePagingInView:self.control animation:^(id<YTPageTransitionContext>  _Nonnull context) {
        [UIView transitionWithView:self.control duration:[context animationDuration] options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [self.control setSelectedIndex:[context toIndex]];
        } completion:nil];
    } completion:^(id<YTPageTransitionContext>  _Nonnull context) {
        self.control.userInteractionEnabled = YES;
        if ([context isCanceled]) {
            [self.control setSelectedIndex:[context fromIndex]];
        }
    }];
}

@end
