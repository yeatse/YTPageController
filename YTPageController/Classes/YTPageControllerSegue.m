//
//  YTPageControllerSegue.m
//  YTPageController
//
//  Created by yeatse on 16/9/20.
//  Copyright © 2016年 Yeatse. All rights reserved.
//

#import "YTPageControllerSegue.h"
#import "YTPageController.h"

#import <objc/runtime.h>

NSString* const YTPageControllerSegueIdentifierPrefix = @"YTPage";

@implementation YTPageControllerSegue

- (void)perform {
    NSAssert([self.sourceViewController isKindOfClass:[YTPageController class]], @"Source view controller (%@) must be kind of YTPageController", self.sourceViewController);
    
    YTPageController* page = self.sourceViewController;
    NSMutableArray* viewControllers = (page.viewControllers ?: @[]).mutableCopy;
    [viewControllers addObject:self.destinationViewController];
    page.viewControllers = viewControllers;
}

@end

@interface YTPageController (StoryboardRelationSupport)

@end

@implementation YTPageController (StoryboardRelationSupport)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(awakeFromNib);
        SEL swizzledSelector = @selector(ytp_awakeFromNib);
        
        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)ytp_awakeFromNib {
    [self ytp_awakeFromNib];
    
    BOOL hasNext = YES;
    NSInteger index = 0;
    while (hasNext) {
        @try {
            NSString* identifier = [NSString stringWithFormat:@"%@_%zd", YTPageControllerSegueIdentifierPrefix, index];
            [self performSegueWithIdentifier:identifier sender:nil];
        } @catch (NSException *exception) {
            if (exception.name == NSInvalidArgumentException) {
                hasNext = NO;
            }
        } @finally {
            index ++;
        }
    }
}

@end
