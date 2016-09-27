//
//  ParallaxHeaderTableViewDataSource2.m
//  YTPageController
//
//  Created by yeatse on 16/9/27.
//  Copyright © 2016年 Yeatse CC. All rights reserved.
//

#import "ParallaxHeaderTableViewDataSource2.h"

@implementation ParallaxHeaderTableViewDataSource2

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Table View Cell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"Title %zd", indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Detail %zd", indexPath.row];
    return cell;
}

@end
