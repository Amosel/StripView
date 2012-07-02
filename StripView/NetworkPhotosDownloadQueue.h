//
//  NetworkPhotoAlbumQueue.h
//  StripView
//
//  Created by Amos Elmaliah on 3/23/12.
//  Copyright (c) 2012 UIMUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIInMemoryCache.h"

#define kHighQualityImageCacheNumberOfPixelsUnderStress 1024*1024*3

/**
 * The operation queue that runs all of the network and processing operations.
 *
 * This is unloaded when the controller's view is unloaded from memory.
 */

@class NIMemoryCache;

@class NetworkPhotosDownloadQueue;
@protocol NetworkPhotoAlbumQueueDelegate

-(void)queue: (NetworkPhotosDownloadQueue*)queue 
didLoadPhoto: (UIImage*) image
     atIndex: (NSInteger) photoIndex
    cacheKey: (NSString*) cacheKey;

@end

@protocol NetworkPhotoAlbumQueueDelegate;
@interface NetworkPhotosDownloadQueue : NSOperationQueue {
@private   
    NSMutableDictionary* _activeRequests;
    NSMutableDictionary* _imageCaches;
    id<NetworkPhotoAlbumQueueDelegate>_delegate;
}

-(id)initWithImageCacheKeys:(NSSet*)types;

/**
 * will use the [Nimbus imageMemoryCache] if nil is served and caches key
 */
-(NIImageMemoryCache*)defaultCache;

-(NIImageMemoryCache*)cacheWithKey:(NSString*)cacheKey;

-(UIImage*)imageAtPhotoIndex:(NSUInteger)photoIndex withCacheKey:(NSString*)cacheKey;

/**
 * creates a new new image cache for key.
 *
 * to be used by the ____ to store same-sized photos
 *
 * Images are stored with a name that corresponds directly to the photo index in the form "%d".
 *
 * IMPORTANT: the place to unload image caches is on view conroller view did unload.
 *
 */
-(void) addImageCacheTypeWithKey:(id)imageCacheTypeKey
    maxNumberOfPixelsUnderStress:(NSUInteger)number;


@property (nonatomic, assign) id<NetworkPhotoAlbumQueueDelegate>delegate;

/**
 * Request an image from a source URL and store the result in the corresponding image cache.
 *
 *      @param source       The image's source URL path.
 *      @param cacheKey     Key to associate the loaded image with an NIImageMemoryCache object.
 *                          if nil, will use defaultCache
 *      @param photoIndex   The photo index used to store the image in the memory cache.
 */

/**
 *  
 */

- (void)requestImageFromSource: (NSString *)source
                      cacheKey: (NSString*)cachesKey
                    photoIndex: (NSInteger)photoIndex;

- (void) cancelRequestWithWithCacheKey:(NSString*)cacheKey
                        andPhotoIndex:(NSInteger)photoIndex;

/*
 * deafult priority:NSOperationQueuePriorityNormal
 */

@property(nonatomic) NSOperationQueuePriority defaultPriority;

@end
