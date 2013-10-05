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
- (void)cacheImage:(NSData *) data forUrl:(NSString *)url;
-( BOOL) loadCachedImageForUrl:(NSString *)url maxSize:(NSInteger) size onSuccess:(JOImageResponseBlock) succeed onFail:(JOImageErrorBlock) failed;
- (BOOL)hasCacheForUrl:(NSString *)url ;
- (void)save:(NSNotification*) noti;
@end
/**/
@interface JOImageCache : NSObject<JOImageCacheProvider>
@property (nonatomic) size_t maxBytesInMemory;
@property (nonatomic,strong) NSString * cachePath;
@end


