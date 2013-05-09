//
//  JOMemoryCache.m
//  liulianclient
//
//  Created by Joost💟Blair on 5/3/13.
//  Copyright (c) 2013 yang alef. All rights reserved.
//

#import "JOImageCache.h"

@interface  CLCache : NSObject

@property (nonatomic) size_t  size;
@property (nonatomic)  double lastUsed;
@property (nonatomic)   int hit;
@property (nonatomic,strong)   id key;
@property (nonatomic,strong)  UIImage * image;
@property (nonatomic)  BOOL inMemory;

@end
/**/
@implementation CLCache

@end

#pragma mark --
@interface JOImageCache(/*Private Methods*/)
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
        _maxBytesInMemory = 5*1024*1024;
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save:) name:UIApplicationDidEnterBackgroundNotification object:self];
    }
    return self;
}
- (BOOL)hasCacheForKey:(id)key 
{
    return [_order containsObject:key];
}
-( BOOL) loadCachedDataForKey:(id)key onSuccess:(JOImageResponseBlock) succeed onFail:(JOImageErrorBlock) failed;
{
    CLCache * t = _objects[key];
    if (t&&t.inMemory)
    {
        succeed(t.image,key);
        return YES;
    }else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            CLCache * loadedCache = [self loadCacheToMemWithKey:key];
            if (loadedCache.image)
            {
                succeed(loadedCache.image,key);
            }else
            {
                failed(key,nil);
            }
            
        });
       
        return YES;
    }
}
- (void)cacheData:(UIImage *) data forKey:(id)key
{
    CLCache * cache  = [[CLCache alloc] init];
    cache.key = key;
    cache.image = data;
    cache.size = 4*data.size.width*data.size.height;
    cache.inMemory = YES;
    cache.lastUsed = [[NSDate date] timeIntervalSince1970];
    _totalBytes+=cache.size;
    _objects[key] = cache;
    [_order addObject: key];
    if (_totalBytes> _maxBytesInMemory)
    {
        CLCache * t =[_objects objectForKey: [_objects allKeys][0] ];
        [self moveToDisk: t];
    }
}
- (CLCache *)loadCacheToMemWithKey:(id)key
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
    cache.inMemory = YES;
    cache.size = data.length;
    _totalBytes+= cache.size;
    _objects[key] = cache;
    return cache;
}
- (void)moveToDisk:(CLCache *)cache
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData * data = UIImagePNGRepresentation(cache.image);
        [data writeToFile:[self cachePathForKey:cache.key] atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_objects removeObjectForKey: cache.key];
            cache.image = nil;
        });
    });
    
    
}
- (void)save:(NSNotification*) noti
{
    for (CLCache * cache in _objects)
    {
        [self moveToDisk: cache];
    }
    NSString * cachePlist = [_cachePath stringByAppendingPathComponent:@"jocache"];
    [_order writeToFile: cachePlist atomically:YES];
}
- (NSString *)cachePathForKey:(NSString *)key
{
    NSString * t = [self.cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", [key hash]]];
    return t;
}
@end
