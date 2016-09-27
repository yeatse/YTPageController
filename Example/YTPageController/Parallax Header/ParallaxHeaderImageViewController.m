//
//  ParallaxHeaderImageViewController.m
//  YTPageController
//
//  Created by yeatse on 16/9/27.
//  Copyright © 2016年 Yeatse CC. All rights reserved.
//

#import "ParallaxHeaderImageViewController.h"

@interface ParallaxHeaderImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ParallaxHeaderImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setCurrentImageIndex:(NSInteger)currentImageIndex {
    if (_currentImageIndex != currentImageIndex) {
        [UIView transitionWithView:_imageView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            if (currentImageIndex % 2 == 0) {
                _imageView.image = [UIImage imageNamed:@"header_bg"];
            } else {
                _imageView.image = [UIImage imageNamed:@"header_bg_1"];
            }
        } completion:nil];
        _currentImageIndex = currentImageIndex;
    }
}

@end
