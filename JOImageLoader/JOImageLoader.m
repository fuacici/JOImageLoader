//
//  JOImageLoader.m
//  liulianclient
//
//  Created by Joost💟Blair on 5/8/13.
//  Copyright (c) 2013 joojoo. All rights reserved.
//

#import "JOImageLoader.h"
#import "JOImageCache.h"
#import <ImageIO/ImageIO.h>
#import "JOImageRequest.h"

#pragma mark JOImageLoader Private Methods
@interface JOImageLoader(/*Private Methods*/)
{
    dispatch_queue_t image_process_queue;
}
@property (nonatomic,strong) NSMutableDictionary * requestMap;

@end
static char * const sImageQueueName = "jo_image_process_queue";
#pragma mark JOImageLoader implementation
@implementation JOImageLoader
- (id)init
{
    self = [super init];
    if (self) {
        _requestMap = [NSMutableDictionary dictionaryWithCapacity:30];
        _cache = [[JOImageCache alloc] init];
        image_process_queue = dispatch_queue_create(sImageQueueName, DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


- (void)dealloc
{
    if (image_process_queue)
    {
// for deployment target lower than iOS 6.0 or Mac OS X 10.8 , ARC will NOT manage dispatch queues for you
#if  !OS_OBJECT_USE_OBJC
        dispatch_release(image_process_queue);
#endif
        image_process_queue = nil;
    }
}

- (BOOL)loadImageWithUrl:(NSString *) urlStr maxSize:(NSInteger) maxsize onSuccess:(JOImageResponseBlock) succeed onFail:(JOImageErrorBlock) failed
{
    BOOL hasCache = [_cache hasCacheForUrl:urlStr];
    if (hasCache)
    {
        //load cache
        [_cache loadCachedImageForUrl:urlStr maxSize: maxsize  onSuccess:^(UIImage *image, NSString *urlString) {
            succeed(image,urlString);
        } onFail:^(NSString *urlString, NSError * err) {
            failed(urlString,err);
        }];
    }else
    {
        //query if there's a request for current url
        NSString * key = [NSString stringWithFormat:@"%@_%d",urlStr,maxsize];
        JOImageRequest * request = _requestMap[key];
        if (!request)
        {
            //create a request for url
            request = [JOImageRequest requestWithUrlString:urlStr onSuccess:^(NSData *data, JOImageRequest *request) {
                dispatch_async(image_process_queue, ^{
                     UIImage *img = nil;
                    if (maxsize< 1 )
                    {
                        img = [[UIImage alloc] initWithData:data];
                    }else
                    {
                        NSDictionary * opts = @{(__bridge id)kCGImageSourceThumbnailMaxPixelSize:@(maxsize),(__bridge id)kCGImageSourceCreateThumbnailFromImageIfAbsent:(id)kCFBooleanTrue};
                        CGImageSourceRef cgimagesrc = CGImageSourceCreateWithData((__bridge CFDataRef)(data),NULL);
                        
                        if (cgimagesrc)
                        {
                            CGImageRef cgimg = CGImageSourceCreateThumbnailAtIndex(cgimagesrc, 0, (__bridge CFDictionaryRef)opts);
                            if (cgimg)
                            {
                                img = [[UIImage alloc] initWithCGImage:cgimg];
                                CGImageRelease(cgimg);
                            }
                            CFRelease(cgimagesrc);
                        }
                    }
                    //notify callbacks
                    dispatch_async(dispatch_get_main_queue(), ^{
                        for (JOImageResponseBlock t in request.callbacks)
                        {
                            t(img,request.urlString);
                        }
                        [_cache cacheImage: data forUrl: request.urlString];
                        [_requestMap removeObjectForKey:key];
                    });
                });
                
            } onFail:^(NSError *err, JOImageRequest *request) {
                for (JOImageResponseBlock t in request.callbacks)
                {
                    t(nil,request.urlString);
                }
                [_requestMap removeObjectForKey:key];
            }];
            _requestMap[ key] = request;
            [request load];            
        }
        [request.callbacks addObject: succeed];
        request = nil;
    }
    return YES;
}
@end