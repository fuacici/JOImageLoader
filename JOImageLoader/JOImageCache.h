//
//  JOMemoryCache.h
//  liulianclient
//
//  Created by Joost💟Blair on 5/3/13.
//  Copyright (c) 2013 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JOImageLoader.h"

@protocol JOImageCacheProvider
@required
- (void)cacheData:(UIImage *) data forKey:(id)key;
-( BOOL) loadCachedDataForKey:(id)key onSuccess:(JOImageResponseBlock) succeed onFail:(JOImageErrorBlock) failed;
- (BOOL)hasCacheForKey:(id)key;
- (void)save:(NSNotification*) noti;
@end
/**/
@interface JOImageCache : NSObject<JOImageCacheProvider>
@property (nonatomic) size_t maxBytesInMemory;
@property (nonatomic,strong) NSString * cachePath;
@end


