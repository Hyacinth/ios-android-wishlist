/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "ViewController.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import "SBJSON.h"
#import "OGProtocols.h"

// View tags
#define WISHLIST_TITLE_TAG 1001
#define PRODUCT_NAME_TAG 1002
#define PLACE_NAME_TAG 1003

// Server for uploading photos and hosting objects
static NSString *kBackEndServer = @"https://growing-leaf-2900.herokuapp.com";

@interface ViewController ()
<UIPickerViewDelegate,
UITableViewDataSource,
UITableViewDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
UITextFieldDelegate,
CLLocationManagerDelegate,
UIAlertViewDelegate,
UIPopoverControllerDelegate,
FBPlacePickerDelegate,
FBDialogDelegate>

@property (nonatomic, retain) UIButton *loginButton;
@property (nonatomic, retain) UIPickerView *wishlistPickerView;
@property (nonatomic, retain) NSMutableArray *wishlistChoices;
@property (nonatomic, assign) NSInteger selectedWishlist;
@property (nonatomic, retain) UITableView *infoTableView;
@property (nonatomic, assign) BOOL wishlistPickerVisible;
@property (nonatomic, retain) UIImageView *productPhotoImageView;
@property (nonatomic, retain) UIImage *productImage;
@property (nonatomic, retain) UIImagePickerController *imagePickerController;
@property (nonatomic, retain) UIButton *cameraButton;
@property (nonatomic, retain) UIButton *libraryButton;
@property (nonatomic, retain) UILabel *cameraLabel;
@property (nonatomic, retain) UILabel *libraryLabel;
@property (nonatomic, retain) NSMutableArray *nearbyData;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *mostRecentLocation;
@property (strong, nonatomic) FBCacheDescriptor *placeCacheDescriptor;
@property (nonatomic, retain) UIView *activityIndicatorView;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UILabel *activityLabel;
@property (nonatomic, retain) NSURLConnection *uploadConnection;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSObject<FBGraphPlace> *selectedPlace;
@property (nonatomic, retain) NSMutableDictionary *productImageData;
@property (nonatomic, retain) NSString *productName;
@property (nonatomic, retain) UILabel *profileNameLabel;
@property (nonatomic, retain) FBProfilePictureView *profileImageView;
@property (strong, nonatomic) UIPopoverController *popover;
@property (nonatomic, retain) Facebook *facebook;

- (void) showLoggedOut;
- (void)setPlaceCacheDescriptorForCoordinates:(CLLocationCoordinate2D)coordinates;

@end

@implementation ViewController

@synthesize loginButton = _loginButton;
@synthesize wishlistPickerView = _wishlistPickerView;
@synthesize wishlistChoices = _wishlistChoices;
@synthesize selectedWishlist = _selectedWishlist;
@synthesize infoTableView = _infoTableView;
@synthesize wishlistPickerVisible = _wishlistPickerVisible;
@synthesize productPhotoImageView = _productPhotoImageView;
@synthesize productImage = _productImage;
@synthesize imagePickerController = _imagePickerController;
@synthesize cameraButton = _cameraButton;
@synthesize libraryButton = _libraryButton;
@synthesize cameraLabel = _cameraLabel;
@synthesize libraryLabel = _libraryLabel;
@synthesize nearbyData = _nearbyData;
@synthesize locationManager = _locationManager;
@synthesize mostRecentLocation = _mostRecentLocation;
@synthesize placeCacheDescriptor = _placeCacheDescriptor;
@synthesize activityIndicatorView = _activityIndicatorView;
@synthesize activityIndicator = _activityIndicator;
@synthesize activityLabel = _activityLabel;
@synthesize uploadConnection = _uploadConnection;
@synthesize receivedData = _receivedData;
@synthesize selectedPlace = _selectedPlace;
@synthesize productImageData = _productImageData;
@synthesize productName = _productName;
@synthesize profileNameLabel = _profileNameLabel;
@synthesize profileImageView = _profileImageView;
@synthesize popover = _popover;
@synthesize facebook = _facebook;

#pragma mark - Facebook API Calls

/*
 * Graph API: Publish the Open Graph action
 */
- (void) publishAddToWishlist
{
    [self showActivityIndicator:@"Adding to Timeline"];
    
    // Get the OG object representing the product
    NSString *productLink = [[NSString alloc]
                             initWithFormat:@"%@/product.php?image=%@&name=%@",
                             kBackEndServer,
                             [self.productImageData objectForKey:@"image_name"],
                             self.productName];
    id<OGProduct> product = (id<OGProduct>)[FBGraphObject graphObject];
    product.url = productLink;
    
    // Get the OG object representing the wishlist
    id<OGWishlist> wishlist = (id<OGWishlist>)[FBGraphObject graphObject];
    wishlist.url = [[self.wishlistChoices objectAtIndex:self.selectedWishlist] objectForKey:@"link"];
    
    // Set up the OG action parameters
    id<OGAddToWishlistAction> action = (id<OGAddToWishlistAction>)[FBGraphObject graphObject];
    // - wishlist object
    action.wishlist = wishlist;
    // - product, custom property for the action
    action.product = product;
    // - place, property for the action (optional)
    if (self.selectedPlace) {
        [action setObject:self.selectedPlace forKey:@"place"];
    }
    // - image, property for the action
    action.image = [self.productImageData objectForKey:@"image_url"];
    
    // Publish the add to wishlist action
    [FBRequestConnection startForPostWithGraphPath:@"me/samplewishlist:add_to"
                                       graphObject:action
                                 completionHandler:^(FBRequestConnection *connection,
                                                     id result,
                                                     NSError *error) {
                                     [self hideActivityIndicator];
                                     [self.view setUserInteractionEnabled:YES];
                                     if (!error) {
                                         [[[UIAlertView alloc] initWithTitle:@"Success"
                                                                     message:@"Your wishlist was added to your timeline."
                                                                    delegate:self
                                                           cancelButtonTitle:@"Done"
                                                           otherButtonTitles:nil,
                                           nil] show];
                                     } else {
                                         NSLog(@"error: domain = %@, code = %d",
                                               error.domain, error.code);
                                         [self showAlertErrorMessage:@"There was an error making your request." ];
                                     }
                                 }];
}

#pragma mark - Helper methods

/*
 * This method shows the activity indicator and
 * deactivates the table to avoid user input.
 */
- (void) showActivityIndicator:(NSString *)message
{
    if (![self.activityIndicator isAnimating]) {
        self.activityIndicatorView.hidden = NO;
        self.infoTableView.userInteractionEnabled = NO;
        if ([message isEqualToString:@""]) {
            self.activityLabel.text = @"Loading";
        } else {
            self.activityLabel.text = message;
        }
        [self.activityIndicator startAnimating];
    }
}

/*
 * This method hides the activity indicator
 * and enables user interaction once more.
 */
- (void) hideActivityIndicator
{
    if ([self.activityIndicator isAnimating]) {
        [self.activityIndicator stopAnimating];
        self.infoTableView.userInteractionEnabled = YES;
        self.activityIndicatorView.hidden = YES;
        self.activityLabel.text = @"";
    }
}

/*
 Called to make sure the text view is visible above the keyboard
 when the keyboard is displayed. Registers for the required
 notifications.
 */
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

/*
 Unregisters for the keyboard notifications.
 */
- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification object:nil];
    
}

/*
 Called when the UIKeyboardDidShowNotification is sent.
 */
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.infoTableView.contentInset = contentInsets;
    self.infoTableView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    UITextField *textField = (UITextField *) [self.view viewWithTag:PRODUCT_NAME_TAG];
    if (!CGRectContainsPoint(aRect, textField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, textField.frame.origin.y+kbSize.height);
        [self.infoTableView setContentOffset:scrollPoint animated:YES];
    }
}

/*
 Called when the UIKeyboardWillHideNotification is sent.
 */
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.infoTableView.contentInset = contentInsets;
    self.infoTableView.scrollIndicatorInsets = contentInsets;
}

/*
 * Helper for generic error messages
 * showin in UIAlertView
 */
- (void) showAlertErrorMessage:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil,
      nil] show];
}

#pragma mark -

/**
 * Show the logged out UI
 */
- (void) showLoggedOut {
    // Clear personal info
    self.profileNameLabel.text = @"";
    // Clear the profile image
    self.profileImageView.profileID = nil;
    
    self.loginButton.hidden = NO;
    self.wishlistPickerView.hidden = YES;
    self.infoTableView.hidden = YES;
}

/**
 * Show the authorization dialog.
 */
- (void)login {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    // The user has initiated a login, so call the openSession method
    // and show the login UX if necessary.
    [appDelegate openSessionWithAllowLoginUI:YES];
}

/**
 * Invalidate the access token and clear the cookie.
 */
- (void)logout {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate closeSession];
}

/*
 * Configure the logged in versus logged out UI
 */
- (void)sessionStateChanged:(NSNotification*)notification {
    if (FBSession.activeSession.isOpen) {
        self.loginButton.hidden = YES;
        self.wishlistPickerView.hidden = NO;
        self.infoTableView.hidden = NO;
        
        // Initiate a Facebook instance and properties
        if (nil == self.facebook) {
            self.facebook = [[Facebook alloc]
                             initWithAppId:FBSession.activeSession.appID
                             andDelegate:nil];
            
            // Store the Facebook session information
            self.facebook.accessToken = FBSession.activeSession.accessToken;
            self.facebook.expirationDate = FBSession.activeSession.expirationDate;
        }
        
        // Get user info
        [FBRequestConnection startForMeWithCompletionHandler:
         ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
             if (!error) {
                 // Set the user's name
                 self.profileNameLabel.text = user.name;
                 // Set the user's profile picture
                 self.profileImageView.profileID = user.id;
             }
         }];
    } else {
        [self showLoggedOut];
        
        // Clear out the Facebook instance
        self.facebook = nil;
    }
}


#pragma mark -

/*
 * Bring the picker up from the bottom
 */
- (void) showWishlistPicker {
    CGRect moveFrame = self.wishlistPickerView.frame;
    moveFrame.origin.y = self.view.bounds.size.height - self.wishlistPickerView.frame.size.height;
    [UIView animateWithDuration:0.5
                          delay:0.5
                        options: UIViewAnimationCurveEaseOut
                     animations:^{
                         self.wishlistPickerView.frame = moveFrame;
                     }
                     completion:^(BOOL finished){
                         self.wishlistPickerVisible = YES;
                     }];
}

/*
 * Send the picker back to the bottom
 */
- (void) hideWishlistPicker {
    CGRect moveFrame = self.wishlistPickerView.frame;
    moveFrame.origin.y = self.view.bounds.size.height + self.wishlistPickerView.frame.size.height;
    [UIView animateWithDuration:0.5
                          delay:1.0
                        options: UIViewAnimationCurveEaseOut
                     animations:^{
                         self.wishlistPickerView.frame = moveFrame;
                     }
                     completion:^(BOOL finished){
                         self.wishlistPickerVisible = NO;
                     }];
}

#pragma mark -

/*
 Called when either the camera or library button is tapped. Sets up the
 image picker and presents it.
 */
- (void)showImagePicker:(UIImagePickerControllerSourceType)sourceType
{
    // Do not show the picker if not supported, example if there is
    // no camera, tapping the camera button will do nothing.
    if ([UIImagePickerController isSourceTypeAvailable:sourceType])
    {
        if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
            if (!self.popover) {
                self.popover = [[UIPopoverController alloc]
                                initWithContentViewController:self.imagePickerController];
                self.popover.delegate = self;
            }
            [self.popover presentPopoverFromRect:CGRectMake(self.view.bounds.size.width,0,10,10)
                                          inView:self.view
                        permittedArrowDirections:UIPopoverArrowDirectionUp
                                        animated:YES];
        } else {
            self.imagePickerController.sourceType = sourceType;
            [self presentModalViewController:self.imagePickerController animated:YES];
        }
    }
}

/*
 Called to show the camera/library buttons. This is needed
 since these buttons share the same space with the image
 taken. So when the selected image is shown the buttons are
 hidden.
 */
-(void) setPhotoButtonsVisibility:(BOOL)showButtons {
    if (showButtons) {
        self.productPhotoImageView.hidden = YES;
        self.libraryButton.hidden = NO;
        self.libraryLabel.hidden = NO;
        self.cameraButton.hidden = NO;
        self.cameraLabel.hidden = NO;
    } else {
        self.productPhotoImageView.hidden = NO;
        self.libraryButton.hidden = YES;
        self.cameraButton.hidden = YES;
        self.libraryLabel.hidden = YES;
        self.cameraLabel.hidden = YES;
    }
}

/*
 * Handles the camera button click
 */
- (void) cameraButtonClicked:(id) sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self setPhotoButtonsVisibility:NO];
        [self showImagePicker:UIImagePickerControllerSourceTypeCamera];
    }
}

/*
 * Handles the photo library click
 */
- (void) libraryButtonClicked:(id) sender {
    [self setPhotoButtonsVisibility:NO];
    [self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
}

/*
 * To help scale and crop the images
 */
- (UIImage *)imageByScalingAndCroppingForSize:(CGSize)targetSize source:(UIImage *)sourceImage
{
	UIImage *newImage = nil;
	CGSize imageSize = sourceImage.size;
	CGFloat width = imageSize.width;
	CGFloat height = imageSize.height;
	CGFloat targetWidth = targetSize.width;
	CGFloat targetHeight = targetSize.height;
	CGFloat scaleFactor = 0.0;
	CGFloat scaledWidth = targetWidth;
	CGFloat scaledHeight = targetHeight;
	CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
	
	if (CGSizeEqualToSize(imageSize, targetSize) == NO)
	{
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
		
        if (widthFactor > heightFactor)
			scaleFactor = widthFactor; // scale to fit height
        else
			scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
		
        // center the image
        if (widthFactor > heightFactor)
		{
			thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
		}
        else
			if (widthFactor < heightFactor)
			{
				thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
			}
	}
	
	UIGraphicsBeginImageContext(targetSize); // this will crop
	
	CGRect thumbnailRect = CGRectZero;
	thumbnailRect.origin = thumbnailPoint;
	thumbnailRect.size.width  = scaledWidth;
	thumbnailRect.size.height = scaledHeight;
	
	[sourceImage drawInRect:thumbnailRect];
	
	newImage = UIGraphicsGetImageFromCurrentImageContext();
	
	//pop the context to get back to the default
	UIGraphicsEndImageContext();
	return newImage;
}

#pragma mark -

- (void)setPlaceCacheDescriptorForCoordinates:(CLLocationCoordinate2D)coordinates {
    self.placeCacheDescriptor =
    [FBPlacePickerViewController cacheDescriptorWithLocationCoordinate:coordinates
                                                        radiusInMeters:1000
                                                            searchText:@""
                                                          resultsLimit:50
                                                      fieldsForRequest:nil];
}

/*
 Method called when user location found. Stops updating the location.
 */
- (void) stopLocationManager
{
    // Stop updating location information
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
}

/*
 Helper method to kick off GPS to get the user's location.
 */
- (void) startLocationManager
{
    // A warning if the user turned off location services.
    if (![CLLocationManager locationServicesEnabled]) {
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled. If you proceed, you will be asked to confirm whether location services should be reenabled." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
    }
    // Start the location manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager startUpdatingLocation];
}

/*
 * Helper method to set the place picker info
 */
- (void) setPlacePickerData:(FBPlacePickerViewController *) placePicker
{
    if (placePicker.selection) {
        // Fill the information in the relevant table row
        UILabel *placeLabel = (UILabel *) [self.view viewWithTag:PLACE_NAME_TAG];
        placeLabel.text = placePicker.selection.name;
        self.selectedPlace = placePicker.selection;
    }
}

#pragma mark -

/*
 Helper method for posting photo.
 */
-(NSURLRequest *) postRequestWithURL:(NSString *)url data: (NSData *)data
                            fileName: (NSString*)fileName
{
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setURL:[NSURL URLWithString:url]];
    
    [urlRequest setHTTPMethod:@"POST"];
    
    NSString *myboundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",myboundary];
    [urlRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *postData = [NSMutableData data];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", myboundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"source\"; filename=\"%@\"\r\n", fileName]dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *contentTypeStream = @"Content-Type: application/octet-stream\r\n\r\n";
    [postData appendData:[contentTypeStream dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[NSData dataWithData:data]];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", myboundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [urlRequest setHTTPBody:postData];
    return urlRequest;
}

/*
 Start sending product information to server
 */
- (void) sendInfoButtonClicked:(id) sender {
    // Do some data checks and throw an error if information has not been
    // provided
    if (self.productImage == nil) {
        [self showAlertErrorMessage:@"Please add a product photo." ];
    } else if ([self.productName isEqualToString:@""]) {
        [self showAlertErrorMessage:@"Please enter a product name." ];
    } else {
        [self showActivityIndicator:@"Uploading photo"];
        
        // Prepare the photo data that will be sent to the server first.
        // We are sending the photo in JPEG format.
        NSData *imageData = UIImageJPEGRepresentation(self.productImage, 90);
        
        // Set up the call to post the photo
        NSURLRequest *urlRequest = [self postRequestWithURL:
                                    [NSString stringWithFormat:@"%@/photo_upload.php",kBackEndServer]
                                                       data:imageData
                                                   fileName:@"myImage"];
        
        self.uploadConnection =[[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    }
    
}

/*
 Clear product information so user can enter new info
 */
- (void) clearProductInfo {
    [self setPhotoButtonsVisibility:YES];
    [self.productPhotoImageView setImage:nil];
    self.productImage = nil;
    self.productName = @"";
    UITextField *textField = (UITextField *) [self.view viewWithTag:PRODUCT_NAME_TAG];
    textField.text = @"";
}

/*
 Send the app request
 */
- (void) sendRequestButtonClicked:(id) sender {
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"Check out this awesome app I am using.",  @"message",
                                   @"Check this out", @"notification_text",
                                   nil];
    
    [self.facebook dialog:@"apprequests"
           andParams:params
         andDelegate:self];
}

#pragma mark - View lifecycle
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    // ----------------------------------
    // Data
    // ----------------------------------
    
    // Wishlist choices
    self.wishlistChoices = [[NSMutableArray alloc] init];
    [self.wishlistChoices addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                @"Birthday Wishlist", @"name",
                                [NSString stringWithFormat:@"%@/wishlists/birthday.php",kBackEndServer], @"link",
                                nil]];
    [self.wishlistChoices addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                @"Holiday Wishlist", @"name",
                                [NSString stringWithFormat:@"%@/wishlists/holiday.php",kBackEndServer], @"link",
                                nil]];
    [self.wishlistChoices addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                @"Wedding Wishlist", @"name",
                                [NSString stringWithFormat:@"%@/wishlists/wedding.php",kBackEndServer], @"link",
                                nil]];
    
    self.selectedWishlist = 0;
    
    self.selectedPlace =  nil;
    
    self.productImageData = [[NSMutableDictionary alloc] init];
    
    self.nearbyData = [[NSMutableArray alloc] init];
    
    self.productImage = nil;
    self.productName = @"";
    
    // Setup main view
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen
                                                  mainScreen].applicationFrame];
    [view setBackgroundColor:[UIColor whiteColor]];
    self.title = @"Home";
    self.view = view;
    
    // ----------------------------------
    // Logged out view elements
    // ----------------------------------
    
    // Login Button
    self.loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.loginButton.frame = CGRectMake(0,0,318,58);
    self.loginButton.center = CGPointMake(self.view.center.x, self.view.center.y);
    [self.loginButton addTarget:self
                    action:@selector(login)
          forControlEvents:UIControlEventTouchUpInside];
    [self.loginButton setImage:
     [UIImage imageNamed:@"FBConnect.bundle/images/LoginWithFacebookNormal@2x.png"]
                 forState:UIControlStateNormal];
    [self.loginButton setImage:
     [UIImage imageNamed:@"FBConnect.bundle/images/LoginWithFacebookPressed@2x.png"]
                 forState:UIControlStateHighlighted];
    [self.loginButton sizeToFit];
    [self.view addSubview:self.loginButton];
    
    // ----------------------------------
    // Logged in view elements
    // ----------------------------------
    
    // Table View for Info
    UIView *headerView = [[UIView alloc]
                          initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    headerView.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
    UIColor *facebookBlue = [UIColor
                             colorWithRed:59.0/255.0
                             green:89.0/255.0
                             blue:152.0/255.0
                             alpha:1.0];
    headerView.backgroundColor = facebookBlue;
    self.profileImageView = [[FBProfilePictureView alloc] initWithFrame:CGRectMake(5, 5, 50, 50)];
    [headerView addSubview:self.profileImageView];
    self.profileNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 5, (self.view.bounds.size.width-60), 20)];
    self.profileNameLabel.backgroundColor = facebookBlue;
    self.profileNameLabel.numberOfLines = 2;
    self.profileNameLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0];
    self.profileNameLabel.textColor = [UIColor whiteColor];
    [headerView addSubview:self.profileNameLabel];
    UIButton *logoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    logoutButton.frame = CGRectMake(60,25,81,29);
    [logoutButton addTarget:self
                     action:@selector(logout)
           forControlEvents:UIControlEventTouchUpInside];
    [logoutButton setImage:
     [UIImage imageNamed:@"FBConnect.bundle/images/LogoutNormal.png"]
                  forState:UIControlStateNormal];
    [logoutButton setImage:
     [UIImage imageNamed:@"FBConnect.bundle/images/LogoutPressed.png"]
                  forState:UIControlStateHighlighted];
    [logoutButton sizeToFit];
    [headerView addSubview:logoutButton];
    
    UIView *footerView = [[UIView alloc]
                          initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 120)];
    footerView.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
    
    // Add to Timeline button
    UIButton *addToTimeLineButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    addToTimeLineButton.frame = CGRectMake(10, 10, (self.view.bounds.size.width - 20), 40);
    addToTimeLineButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    [addToTimeLineButton setTitle:@"Add to Timeline"
                         forState:UIControlStateNormal];
    [addToTimeLineButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [addToTimeLineButton addTarget:self action:@selector(sendInfoButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:addToTimeLineButton];
    
    // Send App Request button
    UIButton *sendRequestButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sendRequestButton.frame = CGRectMake(10, 70, (self.view.bounds.size.width - 20), 40);
    sendRequestButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    [sendRequestButton setTitle:@"Send Request"
                       forState:UIControlStateNormal];
    [sendRequestButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [sendRequestButton addTarget:self action:@selector(sendRequestButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:sendRequestButton];
    
    self.infoTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                 style:UITableViewStylePlain];
    [self.infoTableView setBackgroundColor:[UIColor whiteColor]];
    self.infoTableView.dataSource = self;
    self.infoTableView.delegate = self;
    self.infoTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.infoTableView.tableHeaderView = headerView;
    self.infoTableView.tableFooterView = footerView;
    [self.view addSubview:self.infoTableView];
    
    // Wishlist Picker
    // Place picker beyond the bottom
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
        CGFloat yPickerOffset = self.view.frame.size.height + 216;
        self.wishlistPickerView = [[UIPickerView alloc]initWithFrame: CGRectMake (0, yPickerOffset, self.view.frame.size.width, 216)];
    } else {
        self.wishlistPickerView = [[UIPickerView alloc] init];
        CGSize pickerSize = [self.wishlistPickerView sizeThatFits:CGSizeZero];
        CGFloat yPickerOffset = self.view.frame.size.height + self.wishlistPickerView.frame.size.height;
        CGRect pickerFrame = CGRectMake(0.0,yPickerOffset,pickerSize.width,pickerSize.height);
        self.wishlistPickerView.frame = pickerFrame;
    }
    self.wishlistPickerView.delegate = self;
    self.wishlistPickerView.showsSelectionIndicator = YES;
    [self.view addSubview:self.wishlistPickerView];
    
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    
    // Activity Indicator
    self.activityIndicatorView = [[UIView alloc] initWithFrame:CGRectMake((self.view.center.x-60.0), (self.view.center.y-60.0), 120, 120)];
    self.activityIndicatorView.layer.cornerRadius = 8;
    self.activityIndicatorView.alpha = 0.8;
    self.activityIndicatorView.backgroundColor = [UIColor blackColor];
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(40, 30, 40, 40)];
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [self.activityIndicatorView addSubview:self.activityIndicator];
    self.activityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 90, 120, 20)];
    self.activityLabel.textAlignment = UITextAlignmentCenter;
    self.activityLabel.textColor = [UIColor whiteColor];
    self.activityLabel.backgroundColor = [UIColor clearColor];
    self.activityLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0];
    self.activityLabel.text = @"";
    [self.activityIndicatorView addSubview:self.activityLabel];
    [self.view addSubview:self.activityIndicatorView];
    self.activityIndicatorView.hidden = YES;
    
    // Register for notifications to detect keyboard changes if
    // not an iPad
    if (UIUserInterfaceIdiomPad != UI_USER_INTERFACE_IDIOM()) {
        [self registerForKeyboardNotifications];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Register for notifications on FB session state changes
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(sessionStateChanged:)
     name:FBSessionStateChangedNotification
     object:nil];
    
    // Check the session for a cached token to show the proper authenticated
    // UI. However, since this is not user intitiated, do not show the login UX.
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate openSessionWithAllowLoginUI:NO];
    
    // Get the location manager started
    [self startLocationManager];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
    // Cleanup
    if (self.popover) {
        self.popover.delegate = nil;
    }
    self.popover = nil;
    self.imagePickerController = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!FBSession.activeSession.isOpen) {
        [self showLoggedOut];
    }
}

/*
 This method handles any clean up needed if the view
 is about to disappear.
 */
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Hide the activitiy indicator
    [self hideActivityIndicator];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    if (self.wishlistPickerView) {
        if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
            CGFloat yPickerOffset = self.view.bounds.size.height + 216;
            self.wishlistPickerView.frame = CGRectMake (0, yPickerOffset, self.view.bounds.size.width, 216);
        } else {
            CGFloat yPickerOffset = self.view.frame.size.height + self.wishlistPickerView.frame.size.height;
            self.wishlistPickerView.frame = CGRectMake (0, yPickerOffset, self.view.bounds.size.width, self.wishlistPickerView.frame.size.height);
        }
    }
}

#pragma mark - UITableViewDatasource and UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat rowHeight = 40.0;
    switch (indexPath.section) {
        case 0:
            rowHeight = 40;
            break;
        case 1:
            rowHeight = 220;
            break;
        case 4:
            rowHeight = 60;
            break;
        default:
            break;
    }
    return rowHeight;
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 4) {
        return 0;
    } else {
        return 1;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
        switch (indexPath.section) {
            case 0:
            {
                // Wishlist row
                cell.textLabel.text = @"Wishlist";
                cell.detailTextLabel.text = [[self.wishlistChoices objectAtIndex:self.selectedWishlist] objectForKey:@"name"];
                cell.detailTextLabel.tag = WISHLIST_TITLE_TAG;
                cell.detailTextLabel.textColor = [UIColor darkGrayColor];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            }
            case 1:
            {
                // Camera/Library/Product Photo row
                
                // Product photo
                self.productPhotoImageView = [[UIImageView alloc]
                                         initWithFrame:CGRectMake(20, 10, (cell.contentView.frame.size.width-40), 200)];
                self.productPhotoImageView.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                [self.productPhotoImageView setImage:nil];
                self.productPhotoImageView.hidden = YES;
                [cell.contentView addSubview:self.productPhotoImageView];
                
                // Library button
                self.libraryButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [self.libraryButton setImage:[UIImage imageNamed:@"library.png"] forState:UIControlStateNormal];
                [self.libraryButton addTarget:self action:@selector(libraryButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
                self.libraryButton.frame = CGRectMake(0, 0, 100, 100);
                self.libraryButton.center = CGPointMake((cell.contentView.bounds.size.width*0.75), 100);
                self.libraryButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                [cell.contentView addSubview:self.libraryButton];
                
                // Library label
                self.libraryLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                self.libraryLabel.textAlignment = UITextAlignmentCenter;
                self.libraryLabel.font = [UIFont boldSystemFontOfSize:12.0];
                self.libraryLabel.text = @"Library";
                self.libraryLabel.frame = CGRectMake(0, 0, 100, 20);
                self.libraryLabel.center = CGPointMake((cell.contentView.bounds.size.width*0.75), 160);
                self.libraryLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                [cell.contentView addSubview:self.libraryLabel];
                
                // Camera button
                self.cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
                self.cameraButton.frame = CGRectMake(0, 0, 100, 100);
                self.cameraButton.center = CGPointMake((cell.contentView.bounds.size.width/4), 100);
                [self.cameraButton setImage:[UIImage imageNamed:@"camera.png"] forState:UIControlStateNormal];
                [self.cameraButton addTarget:self action:@selector(cameraButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
                self.cameraButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                [cell.contentView addSubview:self.cameraButton];
                
                // Camera label
                self.cameraLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                self.cameraLabel.textAlignment = UITextAlignmentCenter;
                self.cameraLabel.font = [UIFont boldSystemFontOfSize:12.0];
                self.cameraLabel.text = @"Camera";
                self.cameraLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
                self.cameraLabel.frame = CGRectMake(0, 0, 100, 20);
                self.cameraLabel.center = CGPointMake((cell.contentView.bounds.size.width/4), 160);
                [cell.contentView addSubview:self.cameraLabel];
                
                if (self.productImage) {
                    [self.productPhotoImageView setImage:self.productImage];
                    [self setPhotoButtonsVisibility:NO];
                } else {
                    [self setPhotoButtonsVisibility:YES];
                }
                break;
            }
            case 2:
            {
                // Product name row
                cell.textLabel.text = @"Name";
                UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(5, 10, (cell.contentView.frame.size.width- 15), 20)];
                textField.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                textField.tag = PRODUCT_NAME_TAG;
                textField.textAlignment = UITextAlignmentRight;
                textField.textColor = [UIColor darkGrayColor];
                textField.placeholder = @"Enter name";
                textField.delegate = self;
                textField.text = self.productName;
                [cell.contentView addSubview:textField];
                break;
            }
            case 3:
            {
                // Location row
                cell.textLabel.text = @"Location";
                cell.detailTextLabel.text = @"(optional)";
                cell.detailTextLabel.textColor = [UIColor darkGrayColor];
                cell.detailTextLabel.tag = PLACE_NAME_TAG;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            }
            default:
            {
                break;
            }
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            // Show or hide the wishlist picker based on
            // it's current state, visible or not. This
            // provides an easy way to dismiss the picker
            // by tapping the corresponding table row.
            if (self.wishlistPickerVisible) {
                [self hideWishlistPicker];
            } else {
                [self showWishlistPicker];
            }
            break;
        }
        case 3: {
            // Show the place picker
            FBPlacePickerViewController *placePicker = [[FBPlacePickerViewController alloc] init];
            
            placePicker.title = @"Nearby";
            
            // SIMULATOR BUG:
            // See http://stackoverflow.com/questions/7003155/error-server-did-not-accept-client-registration-68
            // at times the simulator fails to fetch a location; when that happens rather than fetch a
            // a location near 0,0 -- let's look for something new Facebook HQ
            if (self.placeCacheDescriptor == nil) {
                [self setPlaceCacheDescriptorForCoordinates:CLLocationCoordinate2DMake(37.483253, -122.150037)];
            }
            
            placePicker.delegate = self;
            [placePicker configureUsingCachedDescriptor:self.placeCacheDescriptor];
            [placePicker loadData];
            [placePicker presentModallyFromViewController:self
                                                 animated:YES
                                                  handler:^(FBViewController *sender, BOOL donePressed) {
                                                      if (donePressed) {
                                                          // Set the place picker data
                                                          [self setPlacePickerData:placePicker];
                                                      }
                                                  }];
            break;
        }
        default:
        {
            break;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIPickerView Methods
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.wishlistChoices count];
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [[self.wishlistChoices objectAtIndex:row] objectForKey:@"name"];
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedWishlist = row;
    UILabel *wishListLabel = (UILabel *) [self.view viewWithTag:WISHLIST_TITLE_TAG];
    wishListLabel.text = [[self.wishlistChoices objectAtIndex:row] objectForKey:@"name"];
    // Hide the picker after a user choice
    [self hideWishlistPicker];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return self.view.bounds.size.width;
}

#pragma mark - UIImagePickerControllerDelegate

/*
 Called when an image has been chosen from the library or taken from the camera. The
 continue button is made visible so the user can continue the product upload flow.
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
        [self.popover dismissPopoverAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
    
    // Scale and crop image as necessary
	UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
	CGSize targetSize = CGSizeMake(self.productPhotoImageView.bounds.size.width, self.productPhotoImageView.bounds.size.height);
    
    // Save the image so that if table cleared we still have the information
	self.productImage = [self imageByScalingAndCroppingForSize:targetSize source:image];
    [self.productPhotoImageView setImage:self.productImage];
}

/*
 Called when the user cancels the photo picker action.
 */
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
        [self.popover dismissPopoverAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
    [self setPhotoButtonsVisibility:YES];
}

#pragma mark - UIPopoverControllerDelegate
/*
 * For iPad, is user clicks outside popover
 */
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    [self.popover dismissPopoverAnimated:YES];
    [self setPhotoButtonsVisibility:YES];
}

#pragma mark - UITextFieldDelegate
/*
 Return should close keyboard
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

/*
 Save the product name information when the keyboard is dismissed
 */
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.productName = textField.text;
}

#pragma mark - CLLocationManager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    // We will care about horizontal accuracy for this example
    
    // Try and avoid cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return;
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
    // test the measurement to see if it is more accurate than the previous measurement
    if (self.mostRecentLocation == nil || self.mostRecentLocation.horizontalAccuracy > newLocation.horizontalAccuracy) {
        // Store current location
        self.mostRecentLocation = newLocation;
        if (newLocation.horizontalAccuracy <= self.locationManager.desiredAccuracy) {
            // Measurement is good
            
            // Fetch data at this new location, and remember the cache descriptor.
            [self setPlaceCacheDescriptorForCoordinates:newLocation.coordinate];
            [self.placeCacheDescriptor prefetchAndCacheForSession:FBSession.activeSession];
            
            [self stopLocationManager];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if ([error code] != kCLErrorLocationUnknown) {
        [self stopLocationManager];
    }
}

#pragma mark - FBPlacePickerDelegate
- (void)placePickerViewControllerSelectionDidChange:
(FBPlacePickerViewController *)placePicker
{
    // Dismiss view controller based on supported methods
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        // iOS 5+ support
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self dismissModalViewControllerAnimated:YES];
        
    }
    // Set the place picker data
    [self setPlacePickerData:placePicker];
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.receivedData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    return nil;
}

- (void) clearConnection {
    self.receivedData = nil;
    self.uploadConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self hideActivityIndicator];
    
    NSString* responseString = [[NSString alloc] initWithData:self.receivedData
                                                      encoding:NSUTF8StringEncoding];
    NSLog(@"Response from photo upload: %@",responseString);
    [self clearConnection];
    // Check the photo upload server completes successfully
    if ([responseString rangeOfString:@"ERROR:"].location == NSNotFound) {
        SBJSON *jsonParser = [SBJSON new];
        id result = [jsonParser objectWithString:responseString];
        // Look for expected parameter back
        if ([result objectForKey:@"image_name"]) {
            self.productImageData = [result copy];
            // Now that we have successfully uploaded the photo
            // we will make the Graph API call to send our Wishlist
            // information.
            [self publishAddToWishlist];
        } else {
            [self showAlertErrorMessage:@"Could not upload the photo." ];
        }
    } else {
        [self showAlertErrorMessage:@"Could not upload the photo." ];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Err message: %@", [[error userInfo] objectForKey:@"error_msg"]);
    NSLog(@"Err code: %d", [error code]);
    [self hideActivityIndicator];
    [self showAlertErrorMessage:@"Could not upload the photo." ];
    [self clearConnection];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Clear product information, leave wishlist and location along
    [self clearProductInfo];
}

#pragma mark - FBDialogDelegate Methods

/**
 * Called when a UIServer Dialog successfully return.
 */
- (void)dialogDidComplete:(FBDialog *)dialog {
    [[[UIAlertView alloc] initWithTitle:@"Success"
                                message:@"Your request was sent out."
                               delegate:nil
                      cancelButtonTitle:@"Done"
                      otherButtonTitles:nil,
      nil] show];
}

- (void) dialogDidNotComplete:(FBDialog *)dialog {
    NSLog(@"Dialog dismissed.");
}

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error {
    NSLog(@"Error message: %@", [[error userInfo] objectForKey:@"error_msg"]);
    [self showAlertErrorMessage:@"There was an error making your request." ];
}


@end
