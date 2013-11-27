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
@property (nonatomic,strong) NSArray * items;
@end

@implementation JOFirstViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self =[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
      
      
    }
    return  self;
}
- (void)viewDidLoad
{
  [super viewDidLoad];
  NSData * data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"urls" ofType:@"json"] ] ;
  NSError * err  = nil;
  self.items= [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
}
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
        img = [[UIImageView alloc] initWithFrame:CGRectMake(5, 7, 70 , 70)];
        img.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview: img];
    }else
    {
      //set to default img
      img.image =nil;
    }
    [img setImageWithUrlString: _items[indexPath.row] maxSize: 0 placeHolder:nil animate:NO indicator:YES];
    return cell;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 70;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
