//
//  JOImageLoader.h
//  liulianclient
//
//  Created by Joost💟Blair on 5/8/13.
//  Copyright (c) 2013 joojoo. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^JOImageResponseBlock)(UIImage * image, NSString * urlString) ;
typedef void (^JOImageErrorBlock)(NSString* urlString, NSError * err) ;

#pragma mark
@class JOImageCache;
@interface JOImageLoader : NSObject
@property (nonatomic,strong,readonly) JOImageCache * cache;
- (BOOL)loadImageWithUrl:(NSString *) urlStr maxSize:(NSInteger) maxsize onSuccess:(JOImageResponseBlock) succeed onFail:(JOImageErrorBlock) failed;
@end

#pragma mark -
#pragma mark Request
@class JOImageRequest;
typedef void (^JOResponseBlock)(NSData * data, JOImageRequest * request);
typedef void (^JOErrorResponseBlock)(NSError * err , JOImageRequest * request);

@interface JOImageRequest:NSObject<NSURLConnectionDataDelegate>
@property (nonatomic,readonly) NSURLConnection * connection;
@property (nonatomic,readonly) NSString * urlString;
@property (nonatomic,readonly) NSMutableArray  * callbacks;
@property (nonatomic,readonly) NSMutableData * data;
- (void)load;
+ (id)requestWithUrlString:(NSString *) urlStr onSuccess:(JOResponseBlock) succeed onFail:(JOErrorResponseBlock) failed;
@end
