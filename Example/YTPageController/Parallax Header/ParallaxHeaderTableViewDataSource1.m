//
//  ParallaxHeaderTableViewDataSource1.m
//  YTPageController
//
//  Created by yeatse on 16/9/27.
//  Copyright © 2016年 Yeatse CC. All rights reserved.
//

#import "ParallaxHeaderTableViewDataSource1.h"

@implementation ParallaxHeaderTableViewDataSource1

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 50;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"Section #%zd", section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Table View Cell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"Title %zd", indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Subtitle %zd", indexPath.row];
    return cell;
}

@end
