//
//  JOSecondViewController.m
//  DemoImageLoader
//
//  Created by Joost💟Blair on 5/8/13.
//  Copyright (c) 2013 eker. All rights reserved.
//

#import "JOSecondViewController.h"
#import "UIImageView+JOAdditions.h"

@interface JOSecondViewController ()

@end

@implementation JOSecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_imageview setImageWithUrlString:@"http://a29.phobos.apple.com/us/r1000/080/Purple/v4/ce/2f/0a/ce2f0a9e-abf4-1d05-829b-5910f62cbe3f/mzl.iafznefm.jpg"];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
