//
// Copyright 2012 Amos Elmaliah
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <QuartzCore/QuartzCore.h>

#import "NIStripViewController.h"

#import "NimbusCore.h"

#import "NIPhotoView.h"

#import "NIPhotoView.h"


#define kCacheKeyForHighRes @"kCacheKeyForHighRes"
#define kCacheKeyForThumbs @"kCacheKeyForThumbs"

@interface NIStripViewController () <NIPhotoViewDelegate, NetworkPhotoAlbumQueueDelegate>
@end

@implementation NIStripViewController

@synthesize photoAlbumView = _photoAlbumView;
@synthesize animateMovingToNextAndPreviousPhotos = _animateMovingToNextAndPreviousPhotos;
@synthesize photos=_photos;

@synthesize loadingImage;
@synthesize zoomingIsEnabled;
@synthesize photoViewBackgroundColor;
@synthesize zoomingAboveOriginalSizeIsEnabled;

#pragma mark - 
#pragma Memory


- (void)dealloc {
    [self shutdown_NIStripViewController];
    self.loadingImage = nil;
    self.photoViewBackgroundColor = nil;
    
    self.photos = nil;
    [super dealloc];
}

- (void)viewDidUnload {

    [self shutdown_NIStripViewController];
    [super viewDidUnload];
}

#pragma mark -
#pragma mark NSObject

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.animateMovingToNextAndPreviousPhotos = NO;
    }
    return self;
}


#pragma mark -
#pragma mark Private

- (void)addTapGestureToView {
    if ([self isViewLoaded]
        && nil != NIUITapGestureRecognizerClass()
        && [self.photoAlbumView respondsToSelector:@selector(addGestureRecognizer:)]) {
        if (nil == _tapGesture) {
            _tapGesture =
            [[NIUITapGestureRecognizerClass() alloc] initWithTarget: self
                                                             action: @selector(didTap)];
            
            [self.photoAlbumView addGestureRecognizer:_tapGesture];
        }
    }
    
    [_tapGesture setEnabled:YES];
}

#pragma mark -
#pragma mark Layout

-(CGRect)photoAlbumFrameForOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return self.view.bounds;
}


#pragma mark -
#pragma mark UIViewController


- (void)shutdown_NIStripViewController {
    _photoAlbumView = nil;
    [_queue cancelAllOperations];
    
    NI_RELEASE_SAFELY(_tapGesture);
}



- (void)loadView {
    [super loadView];
    // Photo Album View Setup
    
    CGRect photoAlbumViewFrame = [self photoAlbumFrameForOrientation:self.interfaceOrientation];
    _photoAlbumView = [[[NIStripView alloc] initWithFrame:photoAlbumViewFrame] autorelease];
    _photoAlbumView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                                        | UIViewAutoresizingFlexibleHeight);
    _photoAlbumView.backgroundColor = [UIColor whiteColor];
    _photoAlbumView.layer.borderWidth = 1.0;
    _photoAlbumView.layer.borderColor = [UIColor greenColor].CGColor;
    _photoAlbumView.horizontal = YES;
    _photoAlbumView.delegate = self;
    _photoAlbumView.dataSource = self;
    
    [self.view addSubview:_photoAlbumView];
    
    self.zoomingIsEnabled = YES;
    self.zoomingAboveOriginalSizeIsEnabled = NO;
    self.loadingImage = [UIImage imageWithContentsOfFile:
                         NIPathForBundleResource(nil, @"NimbusPhotos.bundle/gfx/default.png")];

    NSSet* cacheKeys = [NSSet setWithObjects:
                        kCacheKeyForThumbs
                        ,kCacheKeyForHighRes
                        , nil];
    _queue = [[NetworkPhotosDownloadQueue alloc] initWithImageCacheKeys:cacheKeys];
    _queue.delegate = self;

    //[self addTapGestureToView];
}


-(void)viewDidLoad
{
    [super viewDidLoad];
    [self.photoAlbumView reloadData];
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}



- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NIIsSupportedOrientation(toInterfaceOrientation);
}



- (void)willRotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
                                duration: (NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.photoAlbumView willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}



- (void)willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
                                         duration: (NSTimeInterval)duration {
    [self.photoAlbumView willAnimateRotationToInterfaceOrientation: toInterfaceOrientation
                                                          duration: duration];
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
                                            duration:duration];
    
    self.photoAlbumView.frame = [self photoAlbumFrameForOrientation:toInterfaceOrientation];;
}

#pragma mark -
#pragma mark NetworkPhotoAlbumQueueDelegate

-(NIPhotoViewPhotoSize)PhotoSizeFromCacheKey:(NSString*)cacheKey
{
    if (cacheKey == kCacheKeyForHighRes)
    {
        return NIPhotoViewPhotoSizeOriginal;
    }
    else if(cacheKey == kCacheKeyForThumbs)
    {
        return NIPhotoViewPhotoSizeThumbnail;
    }
    else
    {
        return NIPhotoViewPhotoSizeUnknown;
    }
}

-(void)queue: (NetworkPhotosDownloadQueue*)queue 
didLoadPhoto: (UIImage*) image
     atIndex: (NSInteger) photoIndex
    cacheKey: (NSString*) cacheKey;
{
    NIPhotoViewPhotoSize photoSize = [self PhotoSizeFromCacheKey:cacheKey];
    for (NIPhotoView* item in _photoAlbumView.visibleItems) {
        if (item.itemIndex == photoIndex) {
            
            // Only replace the photo if it's of a higher quality than one we're already showing.
            if (photoSize > item.photoSize) {
                [item setImage:image photoSize:photoSize];
                
                item.zoomingIsEnabled = ([self isZoomingEnabled]
                                         && (NIPhotoViewPhotoSizeOriginal == photoSize));
                
                // Notify the delegate that the photo has been loaded.
                if (NIPhotoViewPhotoSizeOriginal == photoSize) {
                    [_photoAlbumView notifyDelegatePhotoDidLoadAtIndex:photoIndex];
                }
            }
            break;
        }
    }
}

#pragma mark - 
#pragma mark NIStripViewDelegate

- (void)stripViewDidScroll:(NIStripView *)stripView
{
    
}

- (void)stripViewDidChangeItems:(NIStripView *)stripView
{
    
}

- (void)stripView:(NIStripView*)stripView willDisplayItem:(UIView<NIStripViewItem> *)theItemView
{
    if ([theItemView isKindOfClass:[NIPhotoView class]]) {
        NIPhotoView * viewItem = (NIPhotoView*)theItemView;

        // When we ask the data source for the image we expect the following to happen:
        // 1) If the data source has any image at this index, it should return it and set the
        //    photoSize accordingly.
        // 2) If the returned photo is not the highest quality available, the data source should
        //    start loading the high quality photo and set isLoading to YES.
        // 3) If no photo was available, then the data source should start loading the photo
        //    at its highest available quality and nil should be returned. The loadingImage property
        //    will be displayed until the image is loaded. isLoading should be set to YES.
        
        NIPhotoViewPhotoSize photoSize = NIPhotoViewPhotoSizeUnknown;
        BOOL isLoading = NO;
        CGSize originalPhotoDimensions = CGSizeZero;
        NSUInteger photoIndex = viewItem.itemIndex;
        
        UIImage* image = nil;
        
        NSDictionary* photo = [_photos objectAtIndex:photoIndex];
        
        // Let the photo album view know how large the photo will be once it's fully loaded.
        originalPhotoDimensions = [[photo objectForKey:@"dimensions"] CGSizeValue];
        
        image = [_queue imageAtPhotoIndex:photoIndex
                             withCacheKey:kCacheKeyForHighRes];
        if (nil != image) {
            photoSize = NIPhotoViewPhotoSizeOriginal;
            
        } else {
            NSString* source = [photo objectForKey:@"originalSource"];
            [_queue requestImageFromSource:source 
                                  cacheKey:kCacheKeyForHighRes
                                photoIndex:photoIndex];
            
            isLoading = YES;
            
            // Try to return the thumbnail image if we can.
            image = [_queue imageAtPhotoIndex:photoIndex
                                 withCacheKey:kCacheKeyForThumbs];
            if (nil != image) {
                photoSize = NIPhotoViewPhotoSizeThumbnail;
                
            } else {
                // Load the thumbnail as well.
                NSString* thumbnailSource = [photo objectForKey:@"thumbnailSource"];
                [_queue requestImageFromSource:thumbnailSource
                                      cacheKey:kCacheKeyForThumbs
                                    photoIndex:photoIndex];
                
            }
        }

        viewItem.photoDimensions = originalPhotoDimensions;
        
        if (nil == image) {
            //viewItem.zoomingIsEnabled = NO;
            [viewItem setImage:self.loadingImage photoSize:NIPhotoViewPhotoSizeUnknown];
            
        } else {
            viewItem.zoomingIsEnabled = ([self isZoomingEnabled]
                                     && (NIPhotoViewPhotoSizeOriginal == photoSize));
            if (photoSize > viewItem.photoSize) {
                [viewItem setImage:image photoSize:photoSize];
                
                if (NIPhotoViewPhotoSizeOriginal == photoSize) {
                    [_photoAlbumView notifyDelegatePhotoDidLoadAtIndex:viewItem.itemIndex];
                }
            }
        }
    }
}


- (void)stripView:(NIStripView*)stripView didRecycleItem:(UIView<NIStripViewItem> *)item
{
    // Give the data source the opportunity to kill any asynchronous operations for this
    // now-recycled item.
    if ([stripView.dataSource respondsToSelector:
         @selector(stripView:stopLoadingPhotoAtIndex:)]) {
        [stripView.dataSource stripView: stripView
                stopLoadingPhotoAtIndex: item.itemIndex];
    }

}

-(NSUInteger)numberOfItemsPerPageOnStripView:(NIStripView *)stripView
{
    return 2;
}


#pragma mark - 
#pragma mark NIStripViewDataSource


- (void)stripView: (NIStripView *)stripView stopLoadingPhotoAtIndex: (NSInteger)photoIndex;
{
    // we're not cancelling thumb-nail requests, we want them anyway!
    [_queue cancelRequestWithWithCacheKey:kCacheKeyForHighRes
                            andPhotoIndex:photoIndex];
}


- (NSInteger)numberOfItemsInStripView:(NIStripView *)stripView
{
    return [_photos count];
}

- (UIView<NIStripViewItem> *)stripView:(NIStripView *)stripView
                      itemViewForIndex:(NSInteger)itemIndex 
{
    UIView<NIStripViewItem>* itemView = nil;
    NSString* reuseIdentifier = @"photo";
    itemView = [stripView dequeueReusableItemWithIdentifier:reuseIdentifier];
    if (nil == itemView) {
        itemView = [[[NIPhotoView alloc] init] autorelease];
        itemView.reuseIdentifier = reuseIdentifier;
        itemView.backgroundColor = self.photoViewBackgroundColor;
    }
    
    NIPhotoView* photoView = (NIPhotoView *)itemView;
    photoView.photoStripViewDelegate = self;
    photoView.zoomingAboveOriginalSizeIsEnabled = [self isZoomingAboveOriginalSizeEnabled];
    
    return itemView;
}

#pragma mark -
#pragma mark NIPhotoViewDelegate

- (void)photoScrollViewDidDoubleTapToZoom: (NIPhotoView *)photoScrollView
                                didZoomIn: (BOOL)didZoomIn
{
    
}

#pragma mark -
#pragma mark UIGestureRecognizer


- (void)didTap {
      
    return;
    SEL selector = @selector(toggleChromeVisibility);
    if (self.zoomingIsEnabled) {
        // Cancel any previous delayed performs so that we don't stack them.
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:selector object:nil];
        
        // We need to delay taking action on the first tap in case a second tap comes in, causing
        // a double-tap gesture to be recognized and the photo to be zoomed.
        [self performSelector: selector
                   withObject: nil
                   afterDelay: 0.3];
        
    } else {
        // When zooming is disabled, double-tap-to-zoom is also disabled so we don't have to
        // be as careful; just toggle the chrome immediately.
        //[self toggleChromeVisibility];
    }
}


- (void)stripViewDidChangePages:(NIStripView *)stripView {
    // We animate the scrubber when the chrome won't disappear as a nice touch.
    // We don't bother animating if the chrome disappears when scrolling because the user
    // will barely see the animation happen.
}



#pragma mark -
#pragma mark NIPhotoScrubberViewDelegate



- (void)photoScrubberViewDidChangeSelection:(NIPhotoScrubberView *)photoScrubberView {
    [self.photoAlbumView moveToItemAtIndex:photoScrubberView.selectedPhotoIndex animated:NO];
    
}




#pragma mark -
#pragma mark Actions



- (void)didTapNextButton {
    [self.photoAlbumView moveToNextAnimated:self.animateMovingToNextAndPreviousPhotos];
}



- (void)didTapPreviousButton {
    [self.photoAlbumView moveToPreviousAnimated:self.animateMovingToNextAndPreviousPhotos];
}

@end
