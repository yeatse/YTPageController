//
//  TabBarTransitionDelegate.m
//  YTPageController
//
//  Created by Yang Chao on 16/9/20.
//  Copyright © 2016年 Yeatse CC. All rights reserved.
//

#import "TabBarTransitionDelegate.h"

@interface TabBarTransitionDelegate ()

@property (weak, nonatomic) IBOutlet YTPageController *pageController;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@end

@implementation TabBarTransitionDelegate

- (void)awakeFromNib {
    [super awakeFromNib];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.tabBar.selectedItem = self.tabBar.items.firstObject;
    });
}

- (void)pageController:(YTPageController *)pageController willTransitionToIndex:(NSInteger)index {
    [pageController.pageCoordinator animateAlongsidePagingInView:self.tabBar animation:^(id<YTPageTransitionContext>  _Nonnull context) {
        self.tabBar.userInteractionEnabled = NO;
        self.tabBar.selectedItem = self.tabBar.items[[context toIndex]];
    } completion:^(id<YTPageTransitionContext>  _Nonnull context) {
        if ([context isCanceled]) {
            self.tabBar.selectedItem = self.tabBar.items[[context fromIndex]];
        }
        self.tabBar.userInteractionEnabled = YES;
    }];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    [self.pageController setCurrentIndex:[tabBar.items indexOfObjectIdenticalTo:item] animated:NO];
}

@end
