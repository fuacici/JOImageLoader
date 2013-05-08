//
//  UIImageView+JOAdditions.h
//  liulianclient
//
//  Created by Joost💟Blair on 5/3/13.
//  Copyright (c) 2013 yang alef. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JOImageCache.h"
@class JOImageLoader;
@interface UIImageView(JOAdditions)
+(void) setImageLoader:(JOImageLoader*) tloader;
- (id)setImageWithUrlString:(NSString *) urlstring placeHolder:(UIImage *) placeholder animate:(BOOL) animate;
@end

/**/
