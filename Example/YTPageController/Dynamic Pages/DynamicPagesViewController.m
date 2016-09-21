//
//  DynamicPagesViewController.m
//  YTPageController
//
//  Created by yeatse on 16/9/21.
//  Copyright © 2016年 Yeatse CC. All rights reserved.
//

#import "DynamicPagesViewController.h"
#import "DynamicPagesChildViewController.h"

@interface DynamicPagesViewController ()<YTPageControllerDelegate, YTPageControllerDataSource, UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@end

@implementation DynamicPagesViewController {
    NSArray<NSString*>* _pageNames1;
    NSArray<NSString*>* _pageNames2;
    BOOL _flag;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;
    self.dataSource = self;
    
    _pageNames1 = @[@"First", @"Second", @"Third"];
    _pageNames2 = @[@"Eins", @"Zwei", @"Drei", @"Vier"];
    
    [self reloadPages];
    [self refreshTabBarItems];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)reloadPages:(id)sender {
    _flag = !_flag;
    self.currentIndex = 0;
    [self reloadPages];
    [self refreshTabBarItems];
}

- (void)refreshTabBarItems {
    NSMutableArray<UITabBarItem*>* items = @[].mutableCopy;
    for (NSString* name in _flag ? _pageNames2 : _pageNames1) {
        UITabBarItem* item = [[UITabBarItem alloc] initWithTitle:name image:[UIImage imageNamed:@"tabbar_icon"] selectedImage:[UIImage imageNamed:@"tabbar_icon_hl"]];
        [items addObject:item];
    }
    self.tabBar.items = items;
    self.tabBar.selectedItem = self.tabBar.items[self.currentIndex];
}

#pragma mark - YTPageControllerDelegate

- (void)pageController:(YTPageController *)pageController willTransitionToIndex:(NSInteger)index {
    [self.pageCoordinator animateAlongsidePagingInView:self.tabBar animation:^(id<YTPageTransitionContext>  _Nonnull context) {
        self.tabBar.selectedItem = self.tabBar.items[[context toIndex]];
    } completion:^(id<YTPageTransitionContext>  _Nonnull context) {
        if ([context isCanceled]) {
            self.tabBar.selectedItem = self.tabBar.items[[context fromIndex]];
        }
    }];
}

- (void)pageController:(YTPageController *)pageController didUpdateTransition:(id<YTPageTransitionContext>)context {
    NSLog(@"%s, offset: %f", __func__, [context relativeOffset]);
}

- (void)pageController:(YTPageController *)pageController didEndTransition:(id<YTPageTransitionContext>)context {
    NSLog(@"%s from %zd to %zd, canceled: %d", __func__, [context fromIndex], [context toIndex], [context isCanceled]);
}

#pragma mark - YTPageControllerDataSource 

- (NSInteger)numberOfPagesInPageController:(YTPageController *)pageController {
    return _flag ? _pageNames2.count : _pageNames1.count;
}

- (UIViewController *)pageController:(YTPageController *)pageController pageAtIndex:(NSInteger)index {
    DynamicPagesChildViewController* childVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ChildViewController"];
    childVC.title = (_flag ? _pageNames2 : _pageNames1)[index];
    return childVC;
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    self.currentIndex = [tabBar.items indexOfObjectIdenticalTo:item];
}

@end
