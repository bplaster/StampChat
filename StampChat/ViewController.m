//
//  ViewController.m
//  StampChat
//
//  Created by Brandon Plaster on 2/5/15.
//  Copyright (c) 2015 BrandonPlaster. All rights reserved.
//

#import "ViewController.h"
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface ViewController () <UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate, UITextFieldDelegate, CLLocationManagerDelegate>

// IBOutlets
@property (strong, nonatomic) IBOutlet UITableView *fontTableView;
@property (strong, nonatomic) IBOutlet UIButton *textButton;
@property (strong, nonatomic) IBOutlet UIButton *drawButton;
@property (strong, nonatomic) IBOutlet UIButton *emailButton;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIButton *captureButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *flipButton;
@property (strong, nonatomic) IBOutlet UIView *colorView;

// Views
@property (strong, nonatomic) MFMailComposeViewController *mailComposeViewController;
@property (strong, nonatomic) UITextField *theTextField;
@property (strong, nonatomic) UIImageView *theImageView;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureLayer;
@property (strong, nonatomic) UIView *captureView;
@property (strong, nonatomic) UIView *filterView;
@property (strong, nonatomic) UILabel *locationLabel;
@property (strong, nonatomic) UILabel *accelerationLabel;

// Constants
@property (assign, nonatomic) CGFloat diameter;
@property (strong, nonatomic) NSArray *fontArray;
@property (strong, nonatomic) UIColor *textBackgroundColor;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CMMotionManager *motionManager;

// Variables
@property (assign, nonatomic) BOOL isContinuousStroke;
@property (assign, nonatomic) BOOL isDrawing;
@property (assign, nonatomic) BOOL isCapturing;
@property (assign, nonatomic) BOOL isFontIncreasing;
@property (assign, nonatomic) BOOL isFrontFacing;
@property (assign, nonatomic) BOOL isFiltering;
@property (assign, nonatomic) CGPoint oldTouchPoint;
@property (assign, nonatomic) NSUInteger currentFontIndex;
@property (strong, nonatomic) NSTimer *textTimer;
@property (strong, nonatomic) UIColor *drawColor;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureDeviceInput *currentDeviceInput;

@end

@implementation ViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Setup theImageView
    self.theImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [self.theImageView setUserInteractionEnabled:YES];
    self.isDrawing = NO;
    self.diameter = 7.0;
    self.drawColor = [[UIColor alloc] initWithRed:0 green:0 blue:0 alpha:1];
    CALayer *dbLayer = [self.drawButton layer];
    [dbLayer setCornerRadius:4];
    
    // Setup the captureView
    [self setupCaptureSession];
    
    // Setup the filterView
    [self setupFilterView];
    
    // Initialize fonts for theTextField
    int fontSize = 20;
    UIFont *aGothic = [UIFont fontWithName:@"AppleGothic"               size:fontSize];
    UIFont *ulLight = [UIFont fontWithName:@"HelveticaNeue-UltraLight"  size:fontSize];
    UIFont *mkrFelt = [UIFont fontWithName:@"MarkerFelt-Thin"           size:fontSize];
    UIFont *georgia = [UIFont fontWithName:@"Georgia"                   size:fontSize];
    UIFont *courier = [UIFont fontWithName:@"Courier"                   size:fontSize];
    UIFont *verdana = [UIFont fontWithName:@"Verdana-Bold"              size:fontSize];
    self.fontArray = [[NSArray alloc] initWithObjects:  aGothic,
                      ulLight,
                      mkrFelt,
                      georgia,
                      courier,
                      verdana,
                      nil];
    
    // Setup theTextField
    CGRect textFrame = CGRectMake(0, 0, self.theImageView.frame.size.width, 30);
    self.theTextField = [[UITextField alloc] initWithFrame:textFrame];
    self.currentFontIndex = 0;
    [self.theTextField setFont: [self.fontArray objectAtIndex:self.currentFontIndex]];
    [self.theTextField setEnabled: NO];
    [self.theTextField setHidden:YES];
    [self.theTextField setDelegate:self];
    [self.theTextField setBackgroundColor:[UIColor clearColor]];
    [self.theTextField setTextColor:[UIColor whiteColor]];
    self.textBackgroundColor = [[UIColor alloc] initWithWhite:0.1 alpha:0.5];
    self.isFontIncreasing = YES;
    
    // Add gesture recognizers
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureDidTap:)];
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureDidDrag:)];
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureDidHold:)];
    UISwipeGestureRecognizer *swipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureDidSwipe:)];
   UISwipeGestureRecognizer *swipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureDidSwipe:)];
    swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    swipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;


    
    [panGestureRecognizer setDelegate:self];
    
    [self.theTextField  addGestureRecognizer:panGestureRecognizer];
    [self.theImageView  addGestureRecognizer:tapGestureRecognizer];
    [self.theImageView  addGestureRecognizer:panGestureRecognizer];
    [self.theImageView  addGestureRecognizer:swipeRightGestureRecognizer];
    [self.theImageView  addGestureRecognizer:swipeLeftGestureRecognizer];
    [self.textButton    addGestureRecognizer:longPressGestureRecognizer];

    // Add subviews to views
    [self.view insertSubview:self.captureView atIndex:0];
    [self.view insertSubview:self.theImageView aboveSubview:self.captureView];
    [self.theImageView addSubview:self.theTextField];
    
    // Hide editing view
    [self hideEditingLayer:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

- (void) swipeGestureDidSwipe: (UISwipeGestureRecognizer *)sender {
    if (!self.isCapturing && !self.isDrawing) {
        float duration = 0.3;
        switch (sender.direction) {
            case UISwipeGestureRecognizerDirectionRight:{
                if (self.isFiltering) {
                    self.isFiltering = NO;
                    [UIView animateWithDuration:duration animations:^{
                        [self.filterView setCenter:CGPointMake(self.theImageView.center.x + self.theImageView.bounds.size.width, self.theImageView.center.y)];
                    }];
                } else {
                    self.isFiltering = YES;
                    [self.filterView setCenter:CGPointMake(self.theImageView.center.x - self.theImageView.bounds.size.width, self.theImageView.center.y)];
                    [UIView animateWithDuration:duration animations:^{
                        [self.filterView setCenter:self.theImageView.center];
                    }];
                }
                break;
            }
            case UISwipeGestureRecognizerDirectionLeft:{
                if (self.isFiltering) {
                    self.isFiltering = NO;
                    [UIView animateWithDuration:duration animations:^{
                        [self.filterView setCenter:CGPointMake(self.theImageView.center.x - self.theImageView.bounds.size.width, self.theImageView.center.y)];
                    }];
                } else {
                    self.isFiltering = YES;
                    [self.filterView setCenter:CGPointMake(self.theImageView.center.x + self.theImageView.bounds.size.width, self.theImageView.center.y)];
                    [UIView animateWithDuration:duration animations:^{
                        [self.filterView setCenter:self.theImageView.center];
                    }];
                }
                break;
            }
            default:
                break;
        }
    }
}

- (void) longPressGestureDidHold: (UILongPressGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:{
            [self.textTimer invalidate];
            self.textTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(cycleTextSize) userInfo:nil repeats:YES];
            break;
        }
        case UIGestureRecognizerStateEnded:{
            [self.textTimer invalidate];
            break;
        }
            
        default:
            break;
    }
}

// Handles increase/decrease in text size based on long press gesture
- (void) cycleTextSize {
    CGFloat newSize = self.theTextField.font.pointSize;
    CGFloat sizeChange = 3.0;

    // Minimum font size
    if (newSize <= 9) {
        self.isFontIncreasing = YES;
    }
    
    // Increment font size
    if (!self.isFontIncreasing) {
        sizeChange *= -1.0;
    }
    newSize += sizeChange;
    
    // Maximum font size
    UIFont *newFont = [UIFont fontWithName:self.theTextField.font.fontName size:newSize];
    if (![self textField:self.theTextField doesFit:self.theTextField.text withFont:newFont]) {
        self.isFontIncreasing = NO;
        newFont = self.theTextField.font;
    }
    
    // Update font size
    [self.theTextField setFont:newFont];
    [self.theTextField setBounds:CGRectMake(0, 0, self.theImageView.frame.size.width, self.theTextField.frame.size.height + sizeChange)];
}

- (UIImage *) burnView: (UIView *) view intoImage: (UIImage *) image {
    // Boilerplate for beginning an image context
    UIGraphicsBeginImageContextWithOptions(image.size, YES, 0.0);
    
    // Draw the image in the image context
    CGRect aRectangle = CGRectMake(0,0, image.size.width, image.size.height);
    [image drawInRect:aRectangle];
    
    // Draw the text in the image context
    [view drawViewHierarchyInRect:view.frame afterScreenUpdates:NO];
    
    // Get the image to be returned before ending the image context
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Boilerplate for ending an image context
    UIGraphicsEndImageContext();
    
    return theImage;

}

// Draws line between two points
- (void) drawBetweenPoint: (CGPoint) startPoint andPoint: (CGPoint) endPoint {
    
    UIGraphicsBeginImageContext(self.theImageView.frame.size);
    
    // Draw the image
    [self.theImageView.image drawInRect:self.theImageView.bounds];
    
    // Set stroke properties
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.diameter);
    CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), self.drawColor.CGColor);

    // Draw Line
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), startPoint.x, startPoint.y);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), endPoint.x, endPoint.y);
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    CGContextFlush(UIGraphicsGetCurrentContext());
    
    // Set new image
    self.theImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (void) panGestureDidDrag: (UIPanGestureRecognizer *) sender{
    if (![self.theTextField isFirstResponder] && !self.isCapturing) {
        // Get the touch point from the sender
        CGPoint newTouchPoint = [sender locationInView:self.theImageView];

        switch (sender.state) {
            case UIGestureRecognizerStateBegan:{
                // Initialize oldTouchPoint for this drag
                self.oldTouchPoint = newTouchPoint;
                
                if (self.isDrawing) {
                    self.isContinuousStroke = NO;
                    [self hideEditingLayer:YES];
                }
                break;
            }
            case UIGestureRecognizerStateChanged:{
                if (self.isDrawing) {
                    // Draw line between last and current point
                    self.isContinuousStroke = YES;
                    if (!CGPointEqualToPoint(self.oldTouchPoint, newTouchPoint)) {
                        [self drawBetweenPoint:self.oldTouchPoint andPoint:newTouchPoint];
                    }
                    // TODO: Need to fix this, it's clearly not working
                } else if(CGRectContainsPoint(self.theTextField.frame, newTouchPoint)){
                    // Calculate the change in position since last call of panGestureDidDrag (for this drag)
                    float dx = newTouchPoint.x - self.oldTouchPoint.x;
                    float dy = newTouchPoint.y - self.oldTouchPoint.y;
                    float newX = self.theTextField.center.x;
                    float newY = self.theTextField.center.y;
                    
                    // Check for edge cases
                    int edgeX = roundf(self.theTextField.frame.origin.x + dx);
                    int edgeY = roundf(self.theTextField.frame.origin.y + dy);
                    
                    if (edgeX > 5) {
                        CGFloat width =  [self.theTextField.text sizeWithAttributes:@{NSFontAttributeName:self.theTextField.font}].width;
                        if (edgeX + width <= self.theImageView.frame.size.width) {
                            newX += dx;
                            [self.theTextField setBackgroundColor:[UIColor clearColor]];
                        }
                    } else {
                        [self.theTextField setBackgroundColor:self.textBackgroundColor];
                        [self.theTextField setBounds:CGRectMake(0, 0, self.theImageView.frame.size.width, self.theTextField.frame.size.height)];
                        newX += dx - edgeX;
                    }
                    
                    if (edgeY > 0 && edgeY + self.theTextField.frame.size.height < self.theImageView.frame.size.height) {
                        newY += dy;
                    }
                    
                    // Move the center of the text field by the same amount that the finger moved
                    self.theTextField.center = CGPointMake(newX, newY);
                }
                
                // Set oldTouchPoint
                self.oldTouchPoint = newTouchPoint;
                break;
            }
            case UIGestureRecognizerStateEnded:{
                if (self.isDrawing) {
                    [self drawBetweenPoint:self.oldTouchPoint andPoint:newTouchPoint];
                    [self hideEditingLayer:NO];
                }
                break;
            }
            default:
                break;
        }
    }
}

- (void) tapGestureDidTap: (UITapGestureRecognizer *) sender{
    if (!self.isCapturing) {
        switch (sender.state) {
            case UIGestureRecognizerStateEnded:{
                // Get the touch point from the sender
                CGPoint newTouchPoint = [sender locationInView:self.theImageView];
                
                // Handle drawing a point
                if (self.isDrawing) {
                    // Draw a point
                    [self drawBetweenPoint:newTouchPoint andPoint:newTouchPoint];
                }
                // Handle text creation
                else {
                    newTouchPoint.x = self.theImageView.center.x;
                    if (self.theTextField.isHidden) {
                        [self.theTextField setCenter:newTouchPoint];
                        [self.theTextField setHidden:NO];
                        [self.theTextField setEnabled:YES];
                        [self.theTextField becomeFirstResponder];
                        [self.textButton setHidden:NO];
                        [self.textButton setEnabled:YES];
                        [UIView animateWithDuration:0.06 animations:^{
                            [self.theTextField setBackgroundColor:self.textBackgroundColor];
                        }];
                    } else if ([self.theTextField.text length] == 0) {
                        [UIView animateWithDuration:0.06 animations:^{
                            [self.theTextField setBackgroundColor:[UIColor clearColor]];
                        }];
                        [self updateTextVisibility];
                    } else {
                        [self.theTextField resignFirstResponder];
                    }
                }
                break;
            }
            default:
                break;
        }
    }
}

// Handles hiding all the editing elements (obviously it would be better to just put this in a new layer)
-(void) hideEditingLayer: (BOOL)hide {

    // Hide views
    [self.saveButton setHidden:hide];
    [self.emailButton setHidden:hide];
    [self.drawButton setHidden:hide];
    [self.cancelButton setHidden:hide];
    [self.filterView setHidden:hide];
    if (self.isDrawing) {
        [self.colorView setHidden:hide];
        self.colorView.userInteractionEnabled = !hide;
    }
    
    // Disable views
    [self.saveButton setEnabled:!hide];
    [self.emailButton setEnabled:!hide];
    [self.drawButton setEnabled:!hide];
    [self.cancelButton setEnabled:!hide];
    
    [self updateTextVisibility];
}

// Handles enabling text layer when not necessary
-(void) updateTextVisibility {
    if (self.theTextField.text.length > 0 && !self.isCapturing) {
        if (self.isDrawing) {
            [self.textButton setEnabled:NO];
            [self.textButton setHidden:YES];
            [self.theTextField setEnabled:NO];
        } else {
            [self.textButton setEnabled:YES];
            [self.textButton setHidden:NO];
            [self.theTextField setEnabled:YES];
        }
        [self.theTextField setHidden:NO];
    } else {
        [self.textButton setEnabled:NO];
        [self.textButton setHidden:YES];
        [self.theTextField setEnabled:NO];
        [self.theTextField setHidden:YES];
    }
}

// Stamps layers into image.
- (UIImage *)stampImage {
    // Get the new image, with the latest text burned into the latest position
    UIImage *image = [self burnView:self.theTextField intoImage:self.theImageView.image];
    if (self.isFiltering) {
        image = [self burnView:self.filterView intoImage:image];
    }
    
    // Show the new image
    return image;
}

#pragma mark - IBAction

- (IBAction)saveButtonPressed:(id)sender {

    // Save the image to the photo roll. note that the middle two parameters could have been left nil if we didn't want to do anything particular upon the save completing.
    UIImageWriteToSavedPhotosAlbum([self stampImage], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
}

- (void) image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo{
    // This method is being called once saving to the photoroll is complete.
    NSString *result;
    if (error) {
        result = @"There was an error saving.";
    } else {
        result = @"Photo saved!";
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Status" message:result delegate:self cancelButtonTitle:@"Done" otherButtonTitles: nil];
    [alertView show];

}

- (IBAction)emailButtonPressed:(id)sender {
    
    // Initialize the mail compose view controller
    self.mailComposeViewController = [[MFMailComposeViewController alloc] init];
    if ([MFMailComposeViewController canSendMail]) {
        self.mailComposeViewController.mailComposeDelegate = self;//this requires that this viewController declares that it adheres to <MFMailComposeViewControllerDelegate>, and implements a couple of delegate methods which we did not implement in class
        
        // Set a subject for the email
        [self.mailComposeViewController setSubject:@"Check out my snapsterpiece"];
        
        // Get the image data and add it as an attachment to the email
        NSData *imageData = UIImagePNGRepresentation([self stampImage]);
        [self.mailComposeViewController addAttachmentData:imageData mimeType:@"image/png" fileName:@"snapsterpiece"];
        
        // Show mail compose view controller
        [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
    } else {
        NSLog(@"Can't handle mail.");
    }
}

- (IBAction)drawButtonPressed:(id)sender {
    if (self.isDrawing) {
        [self.drawButton setBackgroundColor:[UIColor clearColor]];
        [self.colorView setHidden:YES];
        self.colorView.userInteractionEnabled = NO;
    } else {
        [self.theTextField resignFirstResponder];
        [self.drawButton setBackgroundColor:self.drawColor];
        [self.colorView setHidden:NO];
        self.colorView.userInteractionEnabled = YES;
    }
    self.isDrawing = !self.isDrawing;
    [self updateTextVisibility];
}

- (IBAction)textButtonPressed:(id)sender {
    self.currentFontIndex++;
    self.currentFontIndex %= self.fontArray.count;
    UIFont *newFont = [self.fontArray objectAtIndex:self.currentFontIndex];
    newFont = [UIFont fontWithName:newFont.fontName size:self.theTextField.font.pointSize];
    [self.theTextField setFont:newFont];
}

// Source: https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/04_MediaCapture.html#//apple_ref/doc/uid/TP40010188-CH5-SW2
- (IBAction)captureButtonPressed:(id)sender {
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                if (self.isFrontFacing) {
                    [videoConnection setVideoMirrored:YES];
                }
                break;
            }
        }
        if (videoConnection) { break; }
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:
     ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
         
         if (imageSampleBuffer) {
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             
             UIImage *image = [[UIImage alloc] initWithData:imageData];
             [self.theImageView setImage:image];
         }
     }];

    // Stop the captureSession
    [self.captureSession stopRunning];
    self.isCapturing = NO;
    
    // Setup Edit mode
    [self hideEditingLayer:NO];
    [self.captureButton setEnabled:NO];
    [self.captureButton setHidden:YES];
    [self.flipButton setEnabled:NO];
    [self.flipButton setHidden:YES];
    
}
- (IBAction)cancelPhotoPressed:(id)sender {
    
    // Start the captureSession
    [self.captureSession startRunning];
    self.isCapturing = YES;
    
    // Hide editing
    self.isDrawing = NO;
    [self.theTextField setText:@""];
    [self hideEditingLayer:YES];
    [self.theImageView setImage:nil];
    [self.captureButton setEnabled:YES];
    [self.captureButton setHidden:NO];
    [self.flipButton setEnabled:YES];
    [self.flipButton setHidden:NO];
    [self.colorView setHidden:YES];
    self.colorView.userInteractionEnabled = NO;
    [self.drawButton setBackgroundColor:[UIColor clearColor]];
}
- (IBAction)flipButtonPressed:(id)sender {
    NSError *error = nil;

    AVCaptureDevice *captureDevice;
    
    if (self.isFrontFacing) {
        captureDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
    } else {
        captureDevice = [self cameraWithPosition:AVCaptureDevicePositionFront];

    }
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.currentDeviceInput];
    [self.captureSession addInput:deviceInput];
    [self.captureSession commitConfiguration];
    
    self.currentDeviceInput = deviceInput;
    self.isFrontFacing = !self.isFrontFacing;
}
- (IBAction)colorButtonPressed:(id)sender {
    UIButton *button = sender;
    self.drawColor = button.backgroundColor;
    [self.drawButton setBackgroundColor:self.drawColor];
}


#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField{
    [self.theTextField resignFirstResponder];
    [self updateTextVisibility];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSMutableString *newString = [[NSMutableString alloc] initWithString:textField.text];
    [newString replaceCharactersInRange:range withString:string];
    
    return [self textField:textField doesFit:newString withFont:textField.font];
}

- (BOOL)textField:(UITextField *)textField doesFit:(NSString *)newString withFont:(UIFont *)newFont {
    CGFloat width =  [newString sizeWithAttributes:@{NSFontAttributeName:newFont}].width;
    return (textField.frame.origin.x + width < self.theImageView.frame.size.width);
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    // Gets called after user sends or cancels
    
    // Dismiss the mail compose view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AVFoundationMethods

- (void)setupCaptureSession {
    self.captureView = [[UIView alloc] initWithFrame:self.theImageView.frame];
    
    // Setup the Capture Session
    NSError *error = nil;
    self.captureSession = [AVCaptureSession new];
    self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    AVCaptureDevice *frontCaptureDevice = [self cameraWithPosition:AVCaptureDevicePositionFront];
    self.currentDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCaptureDevice error:&error];
    [self.captureSession addInput:self.currentDeviceInput];
    self.isFrontFacing = YES;
    
    // Add still image capture
    self.stillImageOutput = [AVCaptureStillImageOutput new];
    NSDictionary *outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG};
    [self.stillImageOutput setOutputSettings:outputSettings];
    if ([self.captureSession canAddOutput:self.stillImageOutput]) {
        [self.captureSession addOutput:self.stillImageOutput];
    }
    
    // Set image layer as camera view
    self.captureLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    [self.captureLayer setFrame:self.captureView.frame];
    [self.captureView.layer addSublayer:self.captureLayer];
    
    // Start running
    [self.captureSession startRunning];
    self.isCapturing = YES;
}

// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
// Source: http://stackoverflow.com/questions/20864372/switch-cameras-with-avcapturesession
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position) return device;
    }
    return nil;
}

#pragma mark - FilterViewMethods
- (void)setupFilterView {
    self.isFiltering = NO;
    self.filterView = [[UIView alloc] initWithFrame:self.theImageView.frame];
    [self.filterView setBackgroundColor:[UIColor blackColor]];
    [self.filterView setAlpha:0.5];
    
    self.locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.theImageView.frame.size.width, 120)];
    self.accelerationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.theImageView.frame.size.width, 120)];
    
    [self.locationLabel setTextAlignment:NSTextAlignmentCenter];
    [self.accelerationLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self.locationLabel     setFont:[UIFont fontWithName:@"AppleGothic" size:30.]];
    [self.accelerationLabel setFont:[UIFont fontWithName:@"AppleGothic" size:30.]];
    
    [self.locationLabel setTextColor:[UIColor whiteColor]];
    [self.accelerationLabel setTextColor:[UIColor whiteColor]];
    
    [self.locationLabel setNumberOfLines:2];
    [self.accelerationLabel setNumberOfLines:3];

    [self.locationLabel setCenter: CGPointMake(self.filterView.center.x, self.filterView.center.y - 150)];
    [self.accelerationLabel setCenter: CGPointMake(self.filterView.center.x, self.filterView.center.y + 150)];
    
    // Add views
    [self.filterView addSubview:self.locationLabel];
    [self.filterView addSubview:self.accelerationLabel];
    [self.filterView setUserInteractionEnabled:NO];
    [self.view addSubview:self.filterView];
    
    [self.filterView setCenter:CGPointMake(self.theImageView.center.x + self.theImageView.bounds.size.width, self.theImageView.center.y)];
    
    // Setup the locationManager
    self.locationManager = [CLLocationManager new];
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
    [self.locationManager setDelegate:self];
    
    // Setup the motionManager
    self.motionManager = [CMMotionManager new];
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        if (self.isFiltering) {
            self.accelerationLabel.text = [NSString stringWithFormat:@"X: %.2f\r"@"Y: %.2f\r"@"Z: %.2f",
                                           accelerometerData.acceleration.x,
                                           accelerometerData.acceleration.y,
                                           accelerometerData.acceleration.z];
        }
    }];
    
    
}

# pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {

    CLLocation *location = [locations lastObject];
    self.locationLabel.text = [NSString stringWithFormat:@"Longitude: %f\r"@"Latitude: %f",
                               location.coordinate.longitude,
                               location.coordinate.latitude];
}

#pragma mark - CleanUp

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
