//
//  JOMemoryCache.m
//  liulianclient
//
//  Created by Joost💟Blair on 5/3/13.
//  Copyright (c) 2013 . All rights reserved.
//

#import "JOImageCache.h"
#import <ImageIO/ImageIO.h>

@interface  CLCache : NSObject

@property (nonatomic) size_t  size;
@property (nonatomic)  double lastUsed;
@property (nonatomic)   int hit;
@property (nonatomic,strong)   id key;
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
        _maxBytesInMemory = 2*1024*1024;
        _totalBytes = 0;
        _cachePath =  NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        NSFileManager * filer = [NSFileManager defaultManager];
        NSString * cachePlist = [_cachePath stringByAppendingPathComponent:@"jocache"];
        if ([filer fileExistsAtPath: cachePlist])
        {
            _objects = [NSKeyedUnarchiver unarchiveObjectWithFile:cachePlist];
        }
        
        if (!_objects)
        {
            _objects = [NSMutableDictionary dictionaryWithCapacity:40];
            
        }
        _file_queue = dispatch_queue_create(sFileQueueName, DISPATCH_QUEUE_SERIAL);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save:) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}
- (BOOL)hasCacheForUrl:(NSString *)url
{
    return _objects[url] !=nil ;
}
-( BOOL) loadCachedImageForUrl:(NSString *)url maxSize:(NSInteger) size onSuccess:(JOImageResponseBlock) succeed onFail:(JOImageErrorBlock) failed
{
    NSString * key = [NSString stringWithFormat:@"%@_%d",url,size];
    dispatch_async(_file_queue, ^{
        UIImage * image = [self loadCacheWithKey: key size:size];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image)
            {
                succeed(image,url);
            }else
            {
                failed(key,nil);
            }
        });
        
    });
    
   
    return YES;
    
}
/*- (void)evictLRU
{
    NSArray * sorted = [[_objects allValues] sortedArrayUsingDescriptors:@[ [[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:YES]]];
    int i =0;
    while (i < sorted.count && _totalBytes  > _maxBytesInMemory)
    {
        CLCache * cache = sorted[i];
        if (cache.image)
        {
            
            if (cache.onDisk)
            {
                //already saved on disk, just release image
                _totalBytes -= cache.size;
                cache.image =nil;
            }else
            {
                 [self moveToDisk: cache];
            }
           
        }
        i++;
    }
}*/
- (void)cacheImage:(NSData *) data forUrl:(NSString *)url
{

    CLCache * cache  = [[CLCache alloc] init];
    cache.key = url;
    cache.size = data.length;
    cache.onDisk = NO;
#if USE_MEM_CACHE
    _totalBytes+=cache.size;
    _objects[cache.key] = cache;
#endif
    [self saveImage:data withCache:cache];
}
- (UIImage *)loadCacheWithKey:(NSString *)key size:(float) maxsize
{
    CLCache * cache = _objects[key];
    if (!cache)
    {
        //may be never get here
        cache = [[CLCache alloc] init];
        cache.key = key;
        cache.cacheFile = [self cachePathForKey:key];
        _objects[key] = cache;
    }
    UIImage * image = nil;
    NSData * data = [NSData dataWithContentsOfFile: cache.cacheFile];
    NSDictionary * opts = @{(__bridge id)kCGImageSourceThumbnailMaxPixelSize:@(maxsize),(__bridge id)kCGImageSourceCreateThumbnailFromImageIfAbsent:(id)kCFBooleanTrue};
    CGImageSourceRef cgimagesrc = CGImageSourceCreateWithData((__bridge CFDataRef)(data),NULL);
    
    if (cgimagesrc)
    {
        CGImageRef cgimg = CGImageSourceCreateThumbnailAtIndex(cgimagesrc, 0, (__bridge CFDictionaryRef)opts);
        if (cgimg)
        {
            image = [[UIImage alloc] initWithCGImage:cgimg];
            CGImageRelease(cgimg);
        }
        CFRelease(cgimagesrc);
    }
    

    if (!image)
    {
        [_objects removeObjectForKey:key];
        return nil;
    }
    cache.onDisk = YES;
    cache.size = data.length;
    cache.lastUsed = [[NSDate date] timeIntervalSince1970];
    return image;
}
- (void)saveImage:(NSData*) data withCache:(CLCache *)cache
{
#if USE_DISK_CACHE
        dispatch_async(_file_queue, ^{
            //the block
            if (!cache.cacheFile) {
                cache.cacheFile =[self cachePathForKey:cache.key];
            }
            [data writeToFile:cache.cacheFile atomically:YES];
#endif
            dispatch_async(dispatch_get_main_queue(), ^{
                cache.onDisk = YES;
            });
#if USE_DISK_CACHE
        });
#endif
}
- (void)save:(NSNotification*) noti
{

    NSString * cachePlist = [_cachePath stringByAppendingPathComponent:@"jocache"];
    BOOL _r =[NSKeyedArchiver archiveRootObject:_objects toFile:cachePlist];
    DebugLog(@"save to file %@",_r?@"success":@"failed");
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
