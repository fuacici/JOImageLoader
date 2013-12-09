//
//  JOImageRequest.m
//  DemoImageLoader
//
//  Created by joost on 13-12-9.
//  Copyright (c) 2013年 eker. All rights reserved.
//

#import "JOImageRequest.h"
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
    _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
    //would NOT STOP loading even if users interacting with touch screen, like dragging.
    [_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_connection start];
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
