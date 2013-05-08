//
//  JOFirstViewController.m
//  DemoImageLoader
//
//  Created by Joost💟Blair on 5/8/13.
//  Copyright (c) 2013 eker. All rights reserved.
//

#import "JOFirstViewController.h"
#import "UIImageView+JOAdditions.h"

@interface JOFirstViewController ()

@end

@implementation JOFirstViewController


- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
}
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier: @"cell"];
    UIImageView * img = (UIImageView*) [cell viewWithTag:20];
    if (!img)
    {
        img = [[UIImageView alloc] initWithFrame:CGRectMake(5, 7, 30, 30)];
        img.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin;
        [cell.contentView addSubview: img];
    }
    [img setImageWithUrlString:@"http://a501.phobos.apple.com/us/r1000/088/Purple/v4/c3/80/18/c380186e-7b1c-b76b-cf96-731987e53932/appicon.png" placeHolder:nil animate:NO indicator:YES];
    return cell;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 10;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
