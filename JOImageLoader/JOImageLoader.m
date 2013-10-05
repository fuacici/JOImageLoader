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
        dispatch_release(image_process_queue);
        image_process_queue = 0;
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
        //query if there's a request
        NSString * key = [NSString stringWithFormat:@"%@_%d",urlStr,maxsize];
        JOImageRequest * request = _requestMap[key];
        if (!request)
        {            
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

#pragma mark -
#pragma mark JOImageRequest
@interface JOImageRequest(/*Private Methods*/)
@property (nonatomic,strong) NSURLRequest * request;
@property (nonatomic,strong) JOResponseBlock succeed;
@property (nonatomic,strong) JOErrorResponseBlock failed;
@end
@implementation JOImageRequest
+ (id)requestWithUrlString:(NSString *) urlStr onSuccess:(JOResponseBlock) succeed onFail:(JOErrorResponseBlock) failed
{
    JOImageRequest * r = [[JOImageRequest alloc] initWithUrlString:urlStr];
    r.succeed = succeed;
    r.failed = failed;
    return r;
}
- (id)initWithUrlString:(NSString *) urlstr
{
    self = [super init];
    if (self) {
        _callbacks=[NSMutableArray arrayWithCapacity:5];
        _urlString = urlstr;
    }
    return self;
}
- (void)load
{
    [_connection cancel];
    _request = [NSURLRequest requestWithURL:[NSURL URLWithString: _urlString]];
    _connection = [NSURLConnection connectionWithRequest:_request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (_data)
    {
        [_data appendData: data];
    }else
    {
        _data = [NSMutableData dataWithData: data];
    }
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _succeed(_data,self);
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _failed(error,self);
}
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    return request;
}
@end