//
//  JOImageRequest.h
//  DemoImageLoader
//
//  Created by joost on 13-12-9.
//  Copyright (c) 2013年 eker. All rights reserved.
//

#import <Foundation/Foundation.h>
#pragma mark - Request

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