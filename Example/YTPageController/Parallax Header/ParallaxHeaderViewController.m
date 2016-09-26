//
//  ParallaxHeaderViewController.m
//  YTPageController
//
//  Created by Yang Chao on 2016/9/25.
//  Copyright © 2016年 Yeatse CC. All rights reserved.
//

#import "ParallaxHeaderViewController.h"
#import <YTPageController/YTPageController.h>

static const CGFloat DefaultHeaderHeight = 210;

@interface ParallaxHeaderViewController ()<UIScrollViewDelegate, YTPageControllerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *proxyScrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *containerScrollView;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentHeightConstraint;

@property (nonatomic) YTPageController* pageController;

@property (nonatomic) UITableViewController* tableView1;
@property (nonatomic) UITableViewController* tableView2;

@end

@implementation ParallaxHeaderViewController {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView1 addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:kNilOptions context:NULL];
    [self.tableView2 addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:kNilOptions context:NULL];
}

- (void)dealloc {
    [self.tableView1 removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize))];
    [self.tableView2 removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize))];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"%@", self.containerScrollView);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Embed Controller"]) {
        self.pageController = segue.destinationViewController;
        self.pageController.delegate = self;
        self.tableView1 = self.pageController.viewControllers.firstObject;
        self.tableView2 = self.pageController.viewControllers.lastObject;
    }
}

- (void)updateViewConstraints {
    if (!self.pageController.inTransition) {
        UITableViewController* currentCtrl = self.pageController.viewControllers[self.pageController.currentIndex];
    }
    
    [super updateViewConstraints];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))]) {
        [self.view setNeedsUpdateConstraints];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view setNeedsUpdateConstraints];
}


#pragma mark - YTPageControllerDelegate

- (void)pageController:(YTPageController *)pageController willTransitionToIndex:(NSInteger)index {
    
}

- (void)pageController:(YTPageController *)pageController didEndTransition:(id<YTPageTransitionContext>)context {
    
}

@end
