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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "NimbusPhotos.h"

#import "NetworkPhotosDownloadQueue.h"

/**
 * A simple strip view controller implementation.
 *
 *      @ingroup Photos-Controllers
 *
 * This controller does not implement the photo album data source, it simply implements
 * some of the most common UI elements that are associated with a photo viewer.
 *
 * For an example of implementing the data source, see the photos examples in the
 * examples directory.
 *
 * <h2>Implementing Delegate Methods</h2>
 *
 * This view controller already implements NIStripViewDelegate. If you want to
 * implement methods of this delegate you should take care to call the super implementation
 * if necessary. The following methods have implementations in this class:
 *
 * - photoAlbumScrollViewDidScroll:
 * - photoAlbumScrollView:didZoomIn:
 * - photoAlbumScrollViewDidChangePages:
 *
 */
@interface NIStripViewController : UIViewController 
<
NIStripViewDelegate, 
NIStripViewDataSource
>
{
@private
    // Views
    NIStripView* _photoAlbumView;
    
    // queue
    NetworkPhotosDownloadQueue* _queue;
    
    // model
    NSArray* _photos;
    
    // Gestures
    UITapGestureRecognizer* _tapGesture;
    
    BOOL _animateMovingToNextAndPreviousPhotos;
    
}
#pragma mark Views

@property (nonatomic, readonly, retain) NIStripView* photoAlbumView;
@property (nonatomic, readwrite, assign) BOOL animateMovingToNextAndPreviousPhotos; // default: no
@property (nonatomic, readwrite, retain) NSArray* photos;

@property (nonatomic, readwrite, retain) UIImage* loadingImage;
@property (nonatomic, readwrite, assign, getter=isZoomingEnabled) BOOL zoomingIsEnabled; // default: yes
@property (nonatomic, readwrite, retain) UIColor* photoViewBackgroundColor; 
@property (nonatomic, assign, getter=isZoomingAboveOriginalSizeEnabled) BOOL zoomingAboveOriginalSizeIsEnabled;

-(CGRect)photoAlbumFrameForOrientation:(UIInterfaceOrientation)toInterfaceOrientation;

@end
