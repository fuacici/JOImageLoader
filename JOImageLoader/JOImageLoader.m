//
//  JOImageLoader.m
//  liulianclient
//
//  Created by Joost💟Blair on 5/8/13.
//  Copyright (c) 2013 joojoo. All rights reserved.
//

#import "JOImageLoader.h"
#import "JOImageCache.h"

#pragma mark JOImageLoader Private Methods
@interface JOImageLoader(/*Private Methods*/)
@property (nonatomic,strong) NSMutableDictionary * requestMap;

@end

#pragma mark JOImageLoader implementation
@implementation JOImageLoader
- (id)init
{
    self = [super init];
    if (self) {
        _requestMap = [NSMutableDictionary dictionaryWithCapacity:30];
        _cache = [[JOImageCache alloc] init];
    }
    return self;
}
- (BOOL)loadImageWithUrl:(NSString *) urlStr onSuccess:(JOImageResponseBlock) succeed onFail:(JOImageErrorBlock) failed
{
    BOOL hasCache = [_cache hasCacheForKey:urlStr];
    if (hasCache)
    {
        //load cache
        [_cache loadCachedDataForKey:urlStr onSuccess:^(UIImage *image, NSString *urlString) {
            succeed(image,urlString);
        } onFail:^(NSString *urlString, NSError * err) {
            failed(urlString,err);
        }];
    }else
    {
        //query if there's a request
        JOImageRequest * request = _requestMap[urlStr];
        if (!request)
        {
            request = [JOImageRequest requestWithUrlString:urlStr onSuccess:^(NSData *data, JOImageRequest *request) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    UIImage * img = [UIImage imageWithData: data];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        for (JOImageResponseBlock t in request.callbacks)
                        {
                            t(img,request.urlString);
                        }
                        [_cache cacheData: img forKey:request.urlString size: data.length];
                        [_requestMap removeObjectForKey:request.urlString];
                    });
                });
                
            } onFail:^(NSError *err, JOImageRequest *request) {
                for (JOImageResponseBlock t in request.callbacks)
                {
                    t(nil,request.urlString);
                }
                [_requestMap removeObjectForKey:request.urlString];
            }];
            _requestMap[ urlStr] = request;
        }
        [request.callbacks addObject: succeed];
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
    JOImageRequest * r = [[JOImageRequest alloc] init];
    r.succeed = succeed;
    r.failed = failed;
    [r loadUrlString: urlStr];
    return r;
}
- (id)init
{
    self = [super init];
    if (self) {
        _callbacks=[NSMutableArray arrayWithCapacity:5];
        
    }
    return self;
}
- (void)loadUrlString:(NSString *) urlstr
{
    NSAssert([NSThread isMainThread], @"Must Be Called in Main Thread!");
    [_connection cancel];
    _request = nil;
    _data  = nil;
    
    _urlString = urlstr;
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