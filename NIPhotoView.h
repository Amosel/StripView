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

#import "NIStripViewItem.h"
#import "NIPhotoViewPhotoSize.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol NIPhotoViewDelegate;
@class NICenteringScrollView;

/**
 * A single photo view that supports zooming and rotation.
 *
 *      @ingroup Photos-Views
 */
@interface NIPhotoView : UIView <
  UIScrollViewDelegate,
  NIStripViewItem> {
@private
  // The photo view to be zoomed.
  UIImageView* _imageView;
  // The scroll view.
  NICenteringScrollView* _scrollView;

  // Photo Information
  NIPhotoViewPhotoSize _photoSize;
  CGSize _photoDimensions;

  // Configurable State
  BOOL _zoomingIsEnabled;
  BOOL _zoomingAboveOriginalSizeIsEnabled;

  UITapGestureRecognizer* _doubleTapGestureRecognizer;

  id<NIPhotoViewDelegate> _photoStripViewDelegate;
}

#pragma mark Configuring Functionality

@property (nonatomic, readwrite, assign, getter=isZoomingEnabled) BOOL zoomingIsEnabled; // default: yes
@property (nonatomic, readwrite, assign, getter=isZoomingAboveOriginalSizeEnabled) BOOL zoomingAboveOriginalSizeIsEnabled; // default: yes
@property (nonatomic, readwrite, assign, getter=isDoubleTapToZoomEnabled) BOOL doubleTapToZoomIsEnabled; // default: yes
@property (nonatomic, readwrite, assign) id<NIPhotoViewDelegate> photoStripViewDelegate;

#pragma mark State

- (UIImage *)image;
- (NIPhotoViewPhotoSize)photoSize;
- (void)setImage:(UIImage *)image photoSize:(NIPhotoViewPhotoSize)photoSize;

@property (nonatomic, readwrite, assign) NSInteger itemIndex;
@property (nonatomic, readwrite, assign) CGSize photoDimensions;

@end

/** @name Configuring Functionality */

/**
 * Whether the photo is allowed to be zoomed.
 *
 * By default this is YES.
 *
 *      @fn NIPhotoView::zoomingIsEnabled
 */

/**
 * Whether small photos can be zoomed at least until they fit the screen.
 *
 * If this is disabled, images smaller than the view size can not be zoomed in beyond
 * their original dimensions.
 *
 * If this is enabled, images smaller than the view size can be zoomed in only until
 * they fit the view bounds.
 *
 * The default behavior in Photos.app allows small photos to be zoomed in.
 *
 *      @attention This will allow photos to be zoomed in even if they don't have any more
 *                 pixels to show, causing the photo to blur. This can look ok for photographs,
 *                 but might not look ok for software design mockups.
 *
 * By default this is YES.
 *
 *      @fn NIPhotoView::zoomingAboveOriginalSizeIsEnabled
 */

/**
 * Whether double-tapping zooms in and out of the image.
 *
 * Available on iOS 3.2 and later.
 *
 * By default this is YES.
 *
 *      @fn NIPhotoView::doubleTapToZoomIsEnabled
 */

/**
 * The photo scroll view delegate.
 *
 *      @fn NIPhotoView::photoStripViewDelegate
 */


/** @name State */

/**
 * The currently-displayed photo.
 *
 *      @fn NIPhotoView::image
 */

/**
 * Set a new photo with a specific size.
 *
 * If image is nil then the photoSize will be overridden as NIPhotoViewPhotoSizeUnknown.
 *
 * Resets the current zoom levels and zooms to fit the image.
 *
 *      @fn NIPhotoView::setImage:photoSize:
 */

/**
 * The index of this photo within a photo album.
 *
 *      @fn NIPhotoView::pageIndex
 */

/**
 * The current size of the photo.
 *
 * This is used to replace the photo only with successively higher-quality versions.
 *
 *      @fn NIPhotoView::photoSize
 */

/**
 * The largest dimensions of the photo.
 *
 * This is used to show the thumbnail at the final image size in case the final image size
 * is smaller than the album's frame. Without this value we have to assume that the thumbnail
 * will take up the full screen. If the final image doesn't take up the full screen, then
 * the photo view will appear to "snap" to the smaller full-size image when the final image
 * does load.
 *
 * CGSizeZero is used to signify an unknown final photo dimension.
 *
 *      @fn NIPhotoView::photoDimensions
 */
