//
//  JOMemoryCache.m
//  liulianclient
//
//  Created by Joost💟Blair on 5/3/13.
//  Copyright (c) 2013 . All rights reserved.
//

#import "JOImageCache.h"

@interface  CLCache : NSObject

@property (nonatomic) size_t  size;
@property (nonatomic)  double lastUsed;
@property (nonatomic)   int hit;
@property (nonatomic,strong)   id key;
@property (nonatomic,strong)  UIImage * image;
@property (nonatomic)  BOOL onDisk;

@end
/**/
@implementation CLCache

@end

#pragma mark --
static const char * sFileQueueName = "joimage_file_queue";
@interface JOImageCache(/*Private Methods*/)
{
    dispatch_queue_t _file_queue;
}
@property (nonatomic,strong) NSMutableDictionary * objects;
@property (nonatomic,strong) NSMutableArray * order;
@property (nonatomic) size_t totalBytes;
@end
/**/
@implementation JOImageCache
- (id)init
{
    self = [super init];
    if (self)
    {
        _objects = [NSMutableDictionary dictionaryWithCapacity:40];
        _maxBytesInMemory = 2*1024*1024;
        _totalBytes = 0;
        _cachePath =  NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        NSFileManager * filer = [NSFileManager defaultManager];
        NSString * cachePlist = [_cachePath stringByAppendingPathComponent:@"jocache"];
        if ([filer fileExistsAtPath: cachePlist])
        {
            _order = [NSMutableArray arrayWithContentsOfFile:cachePlist];
        }else
        {
            _order = [NSMutableArray arrayWithCapacity:40];
            
        }
        _file_queue = dispatch_queue_create(sFileQueueName, DISPATCH_QUEUE_SERIAL);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save:) name:UIApplicationDidReceiveMemoryWarningNotification object:self];
    }
    return self;
}
- (BOOL)hasCacheForUrl:(NSString *)url maxSize:(NSInteger) size
{
    NSString * key = [NSString stringWithFormat:@"%@_%d",url,size];
    return [_order containsObject:key];
}
-( BOOL) loadCachedImageForUrl:(NSString *)url maxSize:(NSInteger) size onSuccess:(JOImageResponseBlock) succeed onFail:(JOImageErrorBlock) failed
{
    NSString * key = [NSString stringWithFormat:@"%@_%d",url,size];
    CLCache * t = _objects[key];
    if (t.image)
    {
        t.lastUsed = [[NSDate date] timeIntervalSince1970];
        succeed(t.image,url);
        return YES;
    }else
    {

        dispatch_async(_file_queue, ^{
            CLCache * loadedCache = [self loadCacheToMemWithKey: key];
            if (loadedCache)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _objects[key] = loadedCache;
                    if (_totalBytes>_maxBytesInMemory)
                    {
                        [self evictLRU];
                    }
                    if (loadedCache.image)
                    {
                        succeed(loadedCache.image,url);
                    }else
                    {
                        failed(key,nil);
                    }
                });
            }
        });
        
       
        return YES;
    }
}
- (void)evictLRU
{
    NSArray * sorted = [[_objects allValues] sortedArrayUsingDescriptors:@[ [[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:YES]]];
    CLCache * t =sorted[0];
    dispatch_async(dispatch_get_main_queue(), ^{
         [_objects removeObjectForKey:t.key];
    });
    if (NO == t.onDisk)
    {
        [self moveToDisk: t];
    }
   
}
- (void)cacheImage:(UIImage *) data forUrl:(NSString *)url maxSize:(NSInteger) imgSize
{
    CLCache * cache  = [[CLCache alloc] init];
    cache.key = [NSString stringWithFormat:@"%@_%d",url,imgSize];
    cache.image = data;
    cache.size = data.size.height*data.size.width*4;
    cache.onDisk = NO;
    cache.lastUsed = [[NSDate date] timeIntervalSince1970];
    _totalBytes+=cache.size;
    _objects[cache.key] = cache;
    [_order addObject: cache.key];
    if (_totalBytes> _maxBytesInMemory)
    {
        [self evictLRU];
    }
}
- (CLCache *)loadCacheToMemWithKey:(NSString *)key
{
    NSData * data = [NSData dataWithContentsOfFile:[self cachePathForKey:key]];
    if (!data)
    {
        [_order removeObject:key];
        return nil;
    }
    CLCache * cache = [[CLCache alloc] init];
    cache.key = key;
    cache.image = [UIImage imageWithData: data];
    cache.onDisk = YES;
    cache.size = cache.image.size.width * cache.image.size.height *4;
    cache.lastUsed = [[NSDate date] timeIntervalSince1970];
    _totalBytes+= cache.size;
    return cache;
}
- (void)moveToDisk:(CLCache *)cache
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * data = UIImagePNGRepresentation(cache.image);
        dispatch_async(_file_queue, ^{
            //the block
            [data writeToFile:[self cachePathForKey:cache.key] atomically:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_objects removeObjectForKey: cache.key];
                _totalBytes -= cache.size;
                cache.image = nil;
            });
        });
    });
    
}
- (void)save:(NSNotification*) noti
{
    for (NSString  * key in _objects)
    {
        [self moveToDisk: _objects[key]];
    }
    NSString * cachePlist = [_cachePath stringByAppendingPathComponent:@"jocache"];
    [_order writeToFile: cachePlist atomically:YES];
}
- (NSString *)cachePathForKey:(NSString *)key
{
    NSString * t = [self.cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", [key hash]]];
    return t;
}
- (void)dealloc
{
    if (_file_queue)
    {
        dispatch_release(_file_queue);
        _file_queue = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
