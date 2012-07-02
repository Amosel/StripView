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

/**
 * A subclass of NIPhotoView that shows a caption beneath the picture.
 *
 * This class is purposefully lightweight and simply presents the caption without providing
 * any means of configuring the caption. This is left as an exercise to the developer.
 */
@interface CaptionedPhotoView : NIPhotoView

@property (nonatomic, readwrite, copy) NSString* caption;

@end