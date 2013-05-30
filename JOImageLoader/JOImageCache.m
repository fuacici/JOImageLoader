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
@property (nonatomic,strong)NSString * cacheFile;

@end
/**/
@implementation CLCache
- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        _size = [decoder decodeIntegerForKey:@"size"];
        _lastUsed = [decoder decodeDoubleForKey:@"lastUsed"];
        _hit = [decoder decodeIntForKey:@"hit"];
        _key  = [decoder decodeObject];
        _cacheFile = [decoder decodeObject];
        _onDisk = YES;
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:_size forKey:@"size"];
    [coder encodeDouble:_lastUsed forKey:@"lastUsed"];
    [coder encodeInt:_hit forKey:@"hit"];
    [coder encodeObject:_key];
    [coder encodeObject:_cacheFile];
    _image = nil;
}
@end
#if DEBUG
    #define USE_MEM_CACHE 1
    #define USE_DISK_CACHE 1
#else
    #define USE_MEM_CACHE 1
    #define USE_DISK_CACHE 1
#endif

#pragma mark --
static const char * sFileQueueName = "joimage_file_queue";
@interface JOImageCache(/*Private Methods*/)
{
    dispatch_queue_t _file_queue;
}
@property (nonatomic,strong) NSMutableDictionary * objects;
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
            _objects = [NSMutableDictionary dictionaryWithContentsOfFile:cachePlist];
        }else
        {
            _objects = [NSMutableDictionary dictionaryWithCapacity:40];
            
        }
        _file_queue = dispatch_queue_create(sFileQueueName, DISPATCH_QUEUE_SERIAL);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save:) name:UIApplicationDidReceiveMemoryWarningNotification object:self];
    }
    return self;
}
- (BOOL)hasCacheForUrl:(NSString *)url maxSize:(NSInteger) size
{
    NSString * key = [NSString stringWithFormat:@"%@_%d",url,size];
    return _objects[key] !=nil ;
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
#if USE_MEM_CACHE
                    _objects[key] = loadedCache;
                    _totalBytes += _maxBytesInMemory;
#endif
                    if (loadedCache.image)
                    {
                        succeed(loadedCache.image,url);
                    }else
                    {
                        failed(key,nil);
                    }
                    if (_totalBytes>_maxBytesInMemory)
                    {
                        [self evictLRU];
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
    int i =0;
    while (i < sorted.count && _totalBytes  > _maxBytesInMemory)
    {
        CLCache * cache = sorted[i];
        [_objects removeObjectForKey:cache.key];
        _totalBytes -= cache.size;
        if (!cache.onDisk)
        {
            [self moveToDisk: cache];
        }
        i++;
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
#if USE_MEM_CACHE
    _totalBytes+=cache.size;
    _objects[cache.key] = cache;
#endif
    if (_totalBytes> _maxBytesInMemory)
    {
        [self evictLRU];
    }

}
- (CLCache *)loadCacheToMemWithKey:(NSString *)key
{
    CLCache * cache = _objects[key];
    if (!cache)
    {
        cache = [[CLCache alloc] init];
        cache.cacheFile = [self cachePathForKey:key];
        _objects[key] = cache;
    }
    NSData * data = [NSData dataWithContentsOfFile: cache.cacheFile];
    if (!data)
    {
        [_objects removeObjectForKey:key];
        return nil;
    }
    cache.key = key;
    cache.image = [UIImage imageWithData: data];
    cache.onDisk = YES;
    cache.size = cache.image.size.width * cache.image.size.height *4;
    cache.lastUsed = [[NSDate date] timeIntervalSince1970];
    return cache;
}
- (void)moveToDisk:(CLCache *)cache
{
#if USE_DISK_CACHE
        dispatch_async(_file_queue, ^{
            NSData * data = UIImagePNGRepresentation(cache.image);
            //the block
            if (!cache.cacheFile) {
                cache.cacheFile =[self cachePathForKey:cache.key];
            }
            [data writeToFile:cache.cacheFile atomically:YES];
#endif
            dispatch_async(dispatch_get_main_queue(), ^{
                _totalBytes -= cache.size;
                cache.image = nil;
            });
#if USE_DISK_CACHE
        });
#endif
}
- (void)save:(NSNotification*) noti
{
    for (NSString  * key in _objects)
    {
        [self moveToDisk: _objects[key]];
    }
    NSString * cachePlist = [_cachePath stringByAppendingPathComponent:@"jocache"];
    [_objects writeToFile: cachePlist atomically:YES];
     
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
