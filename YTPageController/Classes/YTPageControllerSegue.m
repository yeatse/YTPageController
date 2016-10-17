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
    
    NSArray* segueTemplates = [self valueForKey:@"storyboardSegueTemplates"];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", [NSString stringWithFormat:@"^%@_\\d+$", YTPageControllerSegueIdentifierPrefix]];
    NSMutableArray<NSString*>* truncatedIDs = [NSMutableArray array];
    for (id template in segueTemplates) {
        NSString* identifier = [template valueForKey:@"identifier"];
        if ([predicate evaluateWithObject:identifier]) {
            [truncatedIDs addObject:[identifier substringFromIndex:YTPageControllerSegueIdentifierPrefix.length + 1]];
        }
    }
    [truncatedIDs sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [@([obj1 integerValue]) compare:@([obj2 integerValue])];
    }];
    for (NSString* truncatedID in truncatedIDs) {
        NSString* identifier = [NSString stringWithFormat:@"%@_%@", YTPageControllerSegueIdentifierPrefix, truncatedID];
        [self performSegueWithIdentifier:identifier sender:nil];
    }
}

@end
