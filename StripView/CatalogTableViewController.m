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

#import "CatalogTableViewController.h"
#import "NIStripViewController.h"
#import "NimbusOperations.h"
#import "NINetworkJSONRequest.h"

@interface CatalogTableViewController () <NIOperationDelegate>

@property (nonatomic, retain)NSArray* tableContents;

@end

@implementation CatalogTableViewController

@synthesize queue = _queue;
@synthesize tableContents;

- (void)shutdown_NetworkPhotoAlbumViewController {
    
    for (NINetworkRequestOperation* request in _queue.operations) 
    {
        request.delegate = nil;
    }
    [_queue cancelAllOperations];
    
    NI_RELEASE_SAFELY(_pinchGesture);
    NI_RELEASE_SAFELY(_activeRequests);
    NI_RELEASE_SAFELY(_queue);
}


- (void)dealloc {
    [self shutdown_NetworkPhotoAlbumViewController];
    NI_RELEASE_SAFELY(_model);
    NI_RELEASE_SAFELY(tableContents);
    [super dealloc];
}

#pragma mark -
#pragma mark UITableViewController - designated initializer

#define DEFAULT_ROW_HEIGHT 400
#define MIN_ROW_HEIGHT 42

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        
        //`NSString* facebookString = @"http://graph.facebook.com/%@/photos?limit=200";
        NSString* dribbleString = @"http://api.dribbble.com";
        
        self.title = NSLocalizedString(@"Photo Album Catalog", @"");
        _rowHeight = DEFAULT_ROW_HEIGHT;
        _rowHeightFactor = 2.0;
        
        self.tableContents =
        [NSArray arrayWithObjects:
         [NSMutableDictionary dictionaryWithObjectsAndKeys:
          [dribbleString stringByAppendingString:@"/shots/popular"],@"url",
          [NIStripViewController class], @"controllerClass",
          @"Popular Shots", @"title",
          nil],
         [NSMutableDictionary dictionaryWithObjectsAndKeys:
          [dribbleString stringByAppendingString:@"/shots/everyone"], @"url",
          [NIStripViewController class], @"controllerClass",
          @"Everyone's Shots", @"title",
          nil],
         [NSMutableDictionary dictionaryWithObjectsAndKeys:
          [dribbleString stringByAppendingString:@"/shots/debuts"], @"url",
          [NIStripViewController class], @"controllerClass",
          @"Debuts", @"title",
          nil],
         nil];
        _model = [[NITableViewModel alloc] initWithSectionedArray:tableContents
                                                         delegate:self];
    }
    NSAssert(![self isViewLoaded], @"view shuold not be loaded at init %@");
    return self;
}

-(void)loadContent
{
    [self.queue cancelAllOperations];
    NSUInteger rows = [_model tableView:nil numberOfRowsInSection:0];
    for (int i=0; i < rows; i++) {
        id object = [_model objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if ([object isKindOfClass:[NSMutableDictionary class]]) {
            NSDictionary* response = [object objectForKey:@"response-data"];
            if (!response) {
                NSURL* url = [NSURL URLWithString:[object objectForKey:@"url"]];
                NINetworkJSONRequest* request = [[[NINetworkJSONRequest alloc] initWithURL:url] autorelease];
                
                // For request that are swlower
                request.timeout = 200;
                
                [request setDelegate:self];
                [_activeRequests addObject:[url absoluteString]];
                [_queue addOperation:request];
            }
        }
        
    }
}

/*
-(void)updateForPinchScale:(CGFloat)scale atIndexPath:(NSIndexPath*)indexPath initialPinchHeight:(NSUInteger)initialPinchHeight
{
    
    if (indexPath && (indexPath.section != NSNotFound) && (indexPath.row != NSNotFound)) {
        
		CGFloat newHeight = round(MAX(initialPinchHeight * scale, DEFAULT_ROW_HEIGHT));
        
		SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:indexPath.section];
        [sectionInfo replaceObjectInRowHeightsAtIndex:indexPath.row withObject:[NSNumber numberWithFloat:newHeight]];
        // Alternatively, set uniformRowHeight = newHeight.
        
//         Switch off animations during the row height resize, otherwise there is a lag before the user's action is seen.

        BOOL animationsEnabled = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:NO];
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        [UIView setAnimationsEnabled:animationsEnabled];
    }
}
*/


-(void)updateForPinchScale:(CGFloat)scale initialPinchHeight:(NSUInteger)initialPinchHeight
{
    _rowHeight = round(MAX(initialPinchHeight * scale, MIN_ROW_HEIGHT));
    
    BOOL animationsEnabled = NO;// [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:animationsEnabled];
    [self.tableView beginUpdates];
    if (animationsEnabled) [UIView setAnimationDuration:0.05];
    [self.tableView endUpdates];
    [UIView setAnimationsEnabled:animationsEnabled];
}

-(void)handlePinch:(UIPinchGestureRecognizer*)pinchRecognizer {
    
    /*
     There are different actions to take for the different states of the gesture recognizer.
     * On Began, we keet the initial height and the index path of the cell where we started.
     * In Changed, we update the scale and update the table view.
     * On Canceled, set restore the original pinchedIndexPath property to nil.
     * On Ended we don't do a thing.
     */
    static NSIndexPath* pinchedIndexPath = nil;
    static NSUInteger initialPinchHeight;
    
    if (pinchRecognizer.state == UIGestureRecognizerStateBegan) {
        
        CGPoint pinchLocation = [pinchRecognizer locationInView:self.tableView];
        NSIndexPath *newPinchedIndexPath = [self.tableView indexPathForRowAtPoint:pinchLocation];
		pinchedIndexPath = [newPinchedIndexPath retain];
        initialPinchHeight = [self tableView:nil heightForRowAtIndexPath:pinchedIndexPath];
    }
    else {
        if (pinchRecognizer.state == UIGestureRecognizerStateChanged) {
            [self updateForPinchScale:pinchRecognizer.scale initialPinchHeight:initialPinchHeight];
        }
        else if ((pinchRecognizer.state == UIGestureRecognizerStateCancelled))
        {
            [self updateForPinchScale:1 initialPinchHeight:initialPinchHeight];
        }
        else if ((pinchRecognizer.state == UIGestureRecognizerStateEnded))
        {
            
        }
    }
}



#pragma mark -
#pragma mark UIViewController


- (void)loadView {
    [super loadView];
    self.tableView.dataSource = _model;
    self.tableView.pagingEnabled = NO;

    _activeRequests = [[NSMutableSet alloc] init];
    _queue = [[NSOperationQueue alloc] init];
    [_queue setMaxConcurrentOperationCount:5];
}

- (void)viewDidUnload {
    [self shutdown_NetworkPhotoAlbumViewController];

    [super viewDidUnload];
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIPinchGestureRecognizer* pinchRecognizer = [[[UIPinchGestureRecognizer alloc] initWithTarget:self 
                                                                                           action:@selector(handlePinch:)] autorelease];
    [self.tableView addGestureRecognizer:pinchRecognizer];
    
    [self loadContent];

}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //[NINavigationAppearance pushAppearanceForNavigationController:self.navigationController];

    [[UIApplication sharedApplication] setStatusBarStyle: (NIIsPad() ? 
                                                           UIStatusBarStyleBlackOpaque :
                                                           UIStatusBarStyleBlackTranslucent)
                                                animated: animated];
    
    [self.navigationController setNavigationBarHidden:YES];
//    UINavigationBar* navBar = self.navigationController.navigationBar;
//    navBar.barStyle = UIBarStyleBlack;
//    navBar.translucent = YES;

}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //[NINavigationAppearance popAppearanceForNavigationController:self.navigationController animated:YES];

}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    //return toInterfaceOrientation == UIInterfaceOrientationPortrait;
    return NIIsSupportedOrientation(toInterfaceOrientation);
}

- (void)willRotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
                                duration: (NSTimeInterval)duration {
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    for (UIViewController* controller in [self.tableContents valueForKeyPath:@"controller"]) {
        if (controller && [controller isKindOfClass:[UIViewController class]] && [controller isViewLoaded]) {
            [controller willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
        }
    }
}

- (void)willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
                                         duration: (NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
                                            duration:duration];
    
    for (UIViewController* controller in [self.tableContents valueForKeyPath:@"controller"]) {
        if (controller && [controller isKindOfClass:[UIViewController class]] && [controller isViewLoaded]) {
            [controller willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
        }
    }
}


#pragma mark -
#pragma mark NINetworkRequestOperationDelegate

- (void)operationWillFinish:(NINetworkRequestOperation *)operation {
    // This is called from the processing thread in order to allow us to turn the root object
    // into something more interesting.
    
    id object = operation.processedObject;
    NSArray* data = [object objectForKey:@"shots"];

    NSMutableArray* photos = [NSMutableArray arrayWithCapacity:[data count]];
    for (NSDictionary* photo in data) {
        @autoreleasepool {
            // Gather the high-quality photo information.
            NSString* originalImageSource = [photo objectForKey:@"image_url"];
            NSInteger width = [[photo objectForKey:@"width"] intValue];
            NSInteger height = [[photo objectForKey:@"height"] intValue];
            
            // We gather the highest-quality photo's dimensions so that we can size the thumbnails
            // correctly until the high-quality image is downloaded.
            CGSize dimensions = CGSizeMake(width, height);
            
            NSString* thumbnailImageSource = [photo objectForKey:@"image_teaser_url"];
            
            NSDictionary* prunedPhotoInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                             originalImageSource, @"originalSource",
                                             thumbnailImageSource, @"thumbnailSource",
                                             [NSValue valueWithCGSize:dimensions], @"dimensions",
                                             nil];
            [photos addObject:prunedPhotoInfo];
        }
    }
    operation.processedObject = photos;
}


- (void)operationDidFinish:(NINetworkRequestOperation *)operation {
    NSString* url = [[operation url] absoluteString];
    
    // remove self's registery of this operation:
    NSSet* set = [_activeRequests objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [(NSString*)obj isEqualToString:url];
    }];
    if ([set count]) {
        [_activeRequests removeObject:[set anyObject]];
    }
    
     
    NSArray* array = [self.tableContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"url like %@",url]];
    
    NSMutableDictionary* dict = [array objectAtIndex:0];
    [dict setObject:operation.processedObject forKey:@"response-data"];
    NSUInteger row = [self.tableContents indexOfObject:dict];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row
                                                inSection:0];
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView endUpdates];    
}

#pragma mark -
#pragma mark UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //  id object = [_model objectAtIndexPath:indexPath];
    
    //  Class vcClass = [object objectForKey:@"controllerClass"];
    //  id initWith = [object objectForKey:@"initWith"];
    //  NSString* title = [object objectForKey:@"title"];
    //  UIViewController* vc = [[[vcClass alloc] initWith:initWith] autorelease];
    //  vc.title = title;
    //
    //  [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark -
#pragma mark UITableViewDelegate 

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //_rowHeight = self.view.bounds.size.height/_rowHeightFactor;
    return _rowHeight;
}

#pragma mark -
#pragma mark NITableViewModelDelegate


- (UITableViewCell *)tableViewModel: (NITableViewModel *)tableViewModel
                   cellForTableView: (UITableView *)tableView
                        atIndexPath: (NSIndexPath *)indexPath
                         withObject: (id)object {
    
    NSString* identifyer = [object objectForKey:@"controllerClass"];
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifyer];
    
    if (nil == cell) {
        
        cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault
                                       reuseIdentifier: @"row"]
                autorelease];
        
        id response = [object objectForKey:@"response-data"];
        if (!response) 
        {
            cell.textLabel.text = @"loading";
        }
        else
        {
            NSString* title = [object objectForKey:@"title"];
            UIViewController* viewController = [object objectForKey:@"controller"];
            
            
            if (!viewController) {
                Class vcClass = [object objectForKey:@"controllerClass"];
                viewController = [[[vcClass alloc] initWithNibName: nil bundle:nil] autorelease];
                [object setObject:viewController forKey:@"controller"];
            }
            [(NIStripViewController*)viewController setPhotos:response];
            viewController.title = title;
            UIView* view = viewController.view;
            cell.accessoryType = UITableViewCellAccessoryNone;
            for (UIView*viewToRemove in [cell.contentView subviews]) {
                [viewToRemove removeFromSuperview];
            }
            [view setFrame:cell.contentView.bounds];
            [cell.contentView addSubview:view];
        }
    }
    return cell;
}

@end
