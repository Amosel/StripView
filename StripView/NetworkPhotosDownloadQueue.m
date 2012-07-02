//
//  NetworkPhotoAlbumQueue.m
//  StripView
//
//  Created by Amos Elmaliah on 3/23/12.
//  Copyright (c) 2012 UIMUI. All rights reserved.
//

#import "NetworkPhotosDownloadQueue.h"

@implementation NetworkPhotosDownloadQueue

@synthesize delegate = _delegate;
@synthesize defaultPriority;

#pragma mark -
#pragma mark NSObject

-(id)initWithImageCacheKeys:(NSSet*)types;
{
    self = [super init];
    if(self)
    {
        _activeRequests = [[NSMutableDictionary alloc] init];
        _imageCaches = [[NSMutableDictionary alloc] init];
        self.defaultPriority = NSOperationQueuePriorityNormal;
        [self setMaxConcurrentOperationCount:5];
        
        [self addImageCacheTypeWithKeys:types
           maxNumberOfPixelsUnderStress:NSNotFound];
    }
    return self;
}

- (id)init 
{
    self = [self initWithImageCacheKeys:[NSSet setWithObjects:nil]];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    for (NINetworkRequestOperation* request in self.operations) {
        request.delegate = nil;
    }
    [self cancelAllOperations];
    
    NI_RELEASE_SAFELY(_activeRequests);
    NI_RELEASE_SAFELY(_imageCaches);
    [super dealloc];
}



-(void) addImageCacheTypeWithKey:(id)imageCacheTypeKey
                  maxNumberOfPixelsUnderStress:(NSUInteger)number
{
    //fetch or warn about total memory used
    //NSAssert1(number <= kHighQualityImageCacheNumberOfPixelsUnderStress, @"umberOfPixelsUnderStress is too big: %d", number);
    
    number = MIN(kHighQualityImageCacheNumberOfPixelsUnderStress, number);
    
    NIImageMemoryCache* newImageCache = [_imageCaches objectForKey:imageCacheTypeKey];
    if (!newImageCache) {
        
        newImageCache = [[[NIImageMemoryCache alloc] init] autorelease];
        if (NSNotFound != number) {
            [newImageCache setMaxNumberOfPixelsUnderStress:number];
        }
        
        [_imageCaches setObject:newImageCache forKey:imageCacheTypeKey];
    }
}

-(void) addImageCacheTypeWithKeys:(NSSet*)imageCacheTypeKeys
     maxNumberOfPixelsUnderStress:(NSUInteger)number
{    
    for (id key in imageCacheTypeKeys) {
        [self addImageCacheTypeWithKey:key
          maxNumberOfPixelsUnderStress:number];
    }
}

-(UIImage*)imageAtPhotoIndex:(NSUInteger)photoIndex withCacheKey:(NSString*)cacheKey
{
    NIImageMemoryCache* cache = [_imageCaches objectForKey:cacheKey];
    if (!cache) {
        cache = [self defaultCache];
    }
    
    return [cache objectWithName:[self cacheKeyForPhotoIndex:photoIndex]];
}

            
-(NIImageMemoryCache*)defaultCache
{
    return [Nimbus imageMemoryCache];
}

-(NIImageMemoryCache*)cacheWithKey:(NSString*)cacheKey
{
    return [_imageCaches objectForKey:cacheKey];
}


-(NSString*) identifierKeyWithCacheKey:(NSString*)cacheKey index:(NSUInteger) photoIndex
{
    NSString* photoIndexCacheKey = [self cacheKeyForPhotoIndex:photoIndex];
    return [NSString stringWithFormat:@"%@-%@",photoIndexCacheKey, cacheKey];
}

- (NSString *)cacheKeyForPhotoIndex:(NSInteger)photoIndex {
    return [NSString stringWithFormat:@"%d", photoIndex];
}


/* 
 * TODO consider writing some sort of a delegate that deals with difference sizing.
 * The downloader dataSource is expected to be dealing with makign sure that the data comes in the right format to be used.
 */

- (void)requestImageFromSource:(NSString *)source
                      cacheKey:(NSString*)cacheKey
                    photoIndex:(NSInteger)photoIndex 
                      priority:(NSOperationQueuePriority)priorty
{
    
    NIImageMemoryCache* imageCache = [_imageCaches objectForKey:cacheKey];
    NSAssert1(imageCache, @"didn't find image cache with cache key %@", cacheKey);

    // Do not load the thumbnail if it's already in memory, or is already downloading 
    id imageDownloadOperationIdentifierKey = [self identifierKeyWithCacheKey:cacheKey index:photoIndex];
    if ([imageCache containsObjectWithName:imageDownloadOperationIdentifierKey] && 
        [[_activeRequests allKeys] containsObject:imageDownloadOperationIdentifierKey]
        ) 
    {
        return;
    };
        
    NSURL* url = [NSURL URLWithString:source];
    
    // __block is used here to avoid retain cycle. self is retained on the imageDownloadOperation compltion blocks.
    __block NINetworkRequestOperation* imageDownloadOperation = [[[NINetworkRequestOperation alloc] initWithURL:url] autorelease];
    imageDownloadOperation.timeout = 30;
        
    NSString* photoIndexKey = [self cacheKeyForPhotoIndex:photoIndex];
    
    [imageDownloadOperation setDidFinishBlock:^(NIOperation* operation) {

        // this is the main thread.
        assert([NSThread isMainThread]);
        
        UIImage* image = [UIImage imageWithData:imageDownloadOperation.data];
        
        // Store the image in the correct image cache.
        NIImageMemoryCache* imageCache = [_imageCaches objectForKey:cacheKey];
        if (!imageCache) {
            imageCache = [self defaultCache];
        }
        [imageCache storeObject:image withName:photoIndexKey];
        
        // this 
        [self.delegate queue:self didLoadPhoto:image atIndex:photoIndex cacheKey:cacheKey];
        
        //    if (isThumbnail) {
        //      [self.photoScrubberView didLoadThumbnail:image atIndex:photoIndex];
        //    }
        
        [_activeRequests setObject:imageDownloadOperation
                            forKey:imageDownloadOperationIdentifierKey];
    }];
    
    // When this request is canceled (like when we're quickly flipping through an album)
    // the request will fail, so we must be careful to remove the request from the active set.
    [imageDownloadOperation setDidFailWithErrorBlock:^(NIOperation* operation, NSError* error) {
        [_activeRequests removeObjectForKey:imageDownloadOperationIdentifierKey];
    }];
    
    
    // Set the operation priority level.
    [imageDownloadOperation setQueuePriority:priorty];    
    
    // Start the operation.
    
    [_activeRequests setObject:imageDownloadOperation
                        forKey:imageDownloadOperationIdentifierKey];
    
    [self addOperation:imageDownloadOperation];
}

- (void)requestImageFromSource:(NSString *)source
                      cacheKey:(NSString*)cacheKey
                    photoIndex:(NSInteger)photoIndex {
    return [self requestImageFromSource:source 
                               cacheKey:cacheKey 
                             photoIndex:photoIndex 
                               priority:self.defaultPriority];
}


- (void) cancelRequestWithWithCacheKey:(NSString*)cacheKey
                         andPhotoIndex:(NSInteger)photoIndex
{
    NSString* operationIdentifyer = [self identifierKeyWithCacheKey:cacheKey index:photoIndex];
    NINetworkRequestOperation* operation = [_activeRequests objectForKey:operationIdentifyer];
    [_activeRequests removeObjectForKey:operation];
    [operation cancel];
}


@end
