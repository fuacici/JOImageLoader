//
//  UIImageView+JOAdditions.m
//  liulianclient
//
//  Created by Joost💟Blair on 5/3/13.
//  Copyright (c) 2013 yang alef. All rights reserved.
//

#import "UIImageView+JOAdditions.h"
#import <objc/runtime.h>
#import "JOImageLoader.h"
static JOImageLoader * imageLoader =nil;
static char imageUrlKey = '\0';

@interface UIImageView (/*Private Methods*/)
@property (strong, nonatomic) NSString * urlString;
@property (nonatomic) UIActivityIndicatorView * indicator;
@end

@implementation UIImageView(JOAdditions)
- (id)setImageWithUrlString:(NSString *) str placeHolder:(UIImage *) placeholder animate:(BOOL) animate
{

    if (!str)
    {
        self.urlString = nil;
        return nil;
    }
    if ([str isEqualToString: self.urlString])
    {
        return nil;
    }
     self.image = nil;
    self.urlString = str;
    NSAssert(imageLoader!= nil, @"Must have set a Image Loader");
    [self.indicator startAnimating];
    [imageLoader loadImageWithUrl: str onSuccess:^(UIImage *image, NSString *urlString) {
        if ([urlString isEqualToString: self.urlString])
        {
            self.image = image;
            [self.indicator stopAnimating];
        }
                
    } onFail:^(NSString *urlString, NSError *err) {
        if ([urlString isEqualToString: self.urlString])
        {
            self.image = nil;
            [self.indicator stopAnimating];
        }
        
    }];
    return nil;
}

- (NSString *)urlString
{
    return objc_getAssociatedObject(self, &imageUrlKey);
}
- (void)setUrlString:(NSString *)urlString
{
    if (urlString)
    {
        objc_setAssociatedObject(self, &imageUrlKey, urlString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }else
    {
        objc_removeAssociatedObjects(self);
    }
}
+(void) setImageLoader:(JOImageLoader*) tloader
{
    imageLoader = tloader;
}

-(UIActivityIndicatorView*) indicator
{
    UIActivityIndicatorView * indicator = (UIActivityIndicatorView*)[self viewWithTag:999];
    if (!indicator)
    {
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.tag = 999;
        indicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        indicator.hidesWhenStopped = YES;
        [self addSubview: indicator];
    }
    indicator.center = CGPointMake(self.bounds.size.width/2.0f, self.bounds.size.height/2.0f);
    return indicator;
}


@end
