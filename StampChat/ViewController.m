//
//  ViewController.m
//  StampChat
//
//  Created by Brandon Plaster on 2/5/15.
//  Copyright (c) 2015 BrandonPlaster. All rights reserved.
//

#import "ViewController.h"
#import <MessageUI/MessageUI.h>

@interface ViewController () <MFMailComposeViewControllerDelegate>

// IBOutlets
@property (strong, nonatomic) IBOutlet UITextField *theTextField;
@property (strong, nonatomic) IBOutlet UITableView *fontTableView;

// Constants
@property (strong, nonatomic) NSArray *fontArray;

// Variables
@property (assign, nonatomic) BOOL isAlreadyDragging;
@property (assign, nonatomic) CGPoint oldTouchPoint;
@property (strong, nonatomic) UIImageView *theImageView;
@property (nonatomic, strong) MFMailComposeViewController *mailComposeViewController;


@end

@implementation ViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    self.theTextField.font = [self.fontArray objectAtIndex:0];
    
    // Add pan gesture recognizer to theTextField
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureDidDrag:)];
    [self.theTextField addGestureRecognizer:panGestureRecognizer];
    
    // Add image
    self.theImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pic"]];
    [self.view insertSubview:self.theImageView atIndex:0];
}

- (UIImage *) burnText: (NSString *) text intoImage: (UIImage *) image{
    
    // Boilerplate for beginning an image context
    UIGraphicsBeginImageContextWithOptions(image.size, YES, 0.0);
    
    //draw the image in the image context
    CGRect aRectangle = CGRectMake(0,0, image.size.width, image.size.height);
    [image drawInRect:aRectangle];
    
    //draw the text in the image context
    NSDictionary *attributes = @{ NSFontAttributeName: self.theTextField.font,
                                  NSForegroundColorAttributeName: [UIColor blackColor]};
    CGSize size = [self.theTextField.text sizeWithAttributes:attributes];//get size of text
    CGPoint center = self.theTextField.center;//get the center
    CGRect rect = CGRectMake(center.x - size.width/2, center.y - size.height/2, size.width, size.height);//create the rect for the text
    [text drawInRect:rect withAttributes:attributes];
    
    //get the image to be returned before ending the image context
    UIImage *theImage=UIGraphicsGetImageFromCurrentImageContext();
    
    //boilerplate for ending an image context
    UIGraphicsEndImageContext();
    
    return theImage;
}

- (void) panGestureDidDrag: (UIPanGestureRecognizer *) sender{
    
    //get the touch point from the sender
    CGPoint newTouchPoint = [sender locationInView:self.view];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:{
            //initialize oldTouchPoint for this drag
            self.oldTouchPoint = newTouchPoint;
            break;
        }
        case UIGestureRecognizerStateChanged:{
            //calculate the change in position since last call of panGestureDidDrag (for this drag)
            float dx = newTouchPoint.x - self.oldTouchPoint.x;
            float dy = newTouchPoint.y - self.oldTouchPoint.y;
            
            //move the center of the text field by the same amount that the finger moved
            self.theTextField.center = CGPointMake(self.theTextField.center.x + dx, self.theTextField.center.y + dy);
            
            //set oldTouchPoint
            self.oldTouchPoint = newTouchPoint;
            break;
        }
        default:
            break;
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    // Boilerplate for table views
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Add the appropriate font name to the cell
    UIFont *font = [self.fontArray objectAtIndex:indexPath.row];
    cell.textLabel.text = font.fontName;
    cell.textLabel.font = font;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.fontArray.count;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //change the font of the text field
    self.theTextField.font = [self.fontArray objectAtIndex:indexPath.row];
}

#pragma mark - IBAction

- (IBAction)stampButtonPressed:(id)sender {
    
    //get the new image, with the latest text burned into the latest position
    UIImage *image = [self burnText:self.theTextField.text intoImage:self.theImageView.image];
    
    //show the new image
    self.theImageView.image = image;
}

- (IBAction)saveButtonPressed:(id)sender {
    
    //save the image to the photo roll. note that the middle two parameters could have been left nil if we didn't want to do anything particular upon the save completing.
    UIImageWriteToSavedPhotosAlbum(self.theImageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
}

- (void) image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo{
    //this method is being called once saving to the photoroll is complete.
    NSLog(@"photo saved!");
    
}

- (IBAction)textFieldDidEndOnExit:(id)sender {
    [sender resignFirstResponder];    //hide the keyboard
}

- (IBAction)emailButtonPressed:(id)sender {
    
    //initialize the mail compose view controller
    self.mailComposeViewController = [[MFMailComposeViewController alloc] init];
    self.mailComposeViewController.mailComposeDelegate = self;//this requires that this viewController declares that it adheres to <MFMailComposeViewControllerDelegate>, and implements a couple of delegate methods which we did not implement in class
    
    //set a subject for the email
    [self.mailComposeViewController setSubject:@"Check out my snapsterpiece"];
    
    // get the image data and add it as an attachment to the email
    NSData *imageData = UIImagePNGRepresentation(self.theImageView.image);
    [self.mailComposeViewController addAttachmentData:imageData mimeType:@"image/png" fileName:@"snapsterpiece"];
    
    // Show mail compose view controller
    [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    //gets called after user sends or cancels
    
    //dismiss the mail compose view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CleanUp

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
