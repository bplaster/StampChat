//
//  ViewController.m
//  StampChat
//
//  Created by Brandon Plaster on 2/5/15.
//  Copyright (c) 2015 BrandonPlaster. All rights reserved.
//

#import "ViewController.h"
#import <MessageUI/MessageUI.h>

@interface ViewController () <MFMailComposeViewControllerDelegate, UITextFieldDelegate>

// IBOutlets
@property (strong, nonatomic) IBOutlet UITableView *fontTableView;
@property (strong, nonatomic) IBOutlet UIButton *textButton;

// Views
@property (nonatomic, strong) MFMailComposeViewController *mailComposeViewController;
@property (strong, nonatomic) UITextField *theTextField;
@property (strong, nonatomic) UIImageView *theImageView;

// Constants
@property (strong, nonatomic) NSArray *fontArray;
@property (strong, nonatomic) UIColor *textBackgroundColor;

// Variables
@property (assign, nonatomic) BOOL isAlreadyDragging;
@property (assign, nonatomic) CGPoint oldTouchPoint;
@property (assign, nonatomic) BOOL isDrawing;
@property (assign, nonatomic) NSUInteger currentFontIndex;

@end

@implementation ViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup theImageView
    self.theImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pic"]];
    [self.theImageView setUserInteractionEnabled:YES];
    self.isDrawing = NO;
    
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
    self.textBackgroundColor = [[UIColor alloc] initWithWhite:0.1 alpha:0.5];
    
    // Add gesture recognizers
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureDidTap:)];
    [self.theImageView addGestureRecognizer:tapGestureRecognizer];
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureDidDrag:)];
    [self.theTextField addGestureRecognizer:panGestureRecognizer];
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureDidHold:)];
    [self.textButton addGestureRecognizer:longPressGestureRecognizer];

    // Add subviews to views
    [self.view insertSubview:self.theImageView atIndex:0];
    [self.theImageView addSubview:self.theTextField];

}

- (void) longPressGestureDidHold: (UILongPressGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:{
            NSLog(@"Long press began!");

            break;
        }
        case UIGestureRecognizerStateEnded:{
            NSLog(@"Long press ended!");

            break;
        }
            
        default:
            break;
    }
}

- (UIImage *) burnText: (NSString *) text intoImage: (UIImage *) image{
    
    // Boilerplate for beginning an image context
    UIGraphicsBeginImageContextWithOptions(image.size, YES, 0.0);
    
    // Draw the image in the image context
    CGRect aRectangle = CGRectMake(0,0, image.size.width, image.size.height);
    [image drawInRect:aRectangle];
    
    // Draw the text in the image context
    [self.theTextField drawViewHierarchyInRect:self.theTextField.frame afterScreenUpdates:NO];
    
    // Get the image to be returned before ending the image context
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Boilerplate for ending an image context
    UIGraphicsEndImageContext();
    
    return theImage;
}

- (void) panGestureDidDrag: (UIPanGestureRecognizer *) sender{
    
    if (![self.theTextField isFirstResponder]) {
        // Get the touch point from the sender
        CGPoint newTouchPoint = [sender locationInView:self.theImageView];
        
        switch (sender.state) {
            case UIGestureRecognizerStateBegan:{
                // Initialize oldTouchPoint for this drag
                self.oldTouchPoint = newTouchPoint;
                break;
            }
            case UIGestureRecognizerStateChanged:{
                // Calculate the change in position since last call of panGestureDidDrag (for this drag)
                float dx = newTouchPoint.x - self.oldTouchPoint.x;
                float dy = newTouchPoint.y - self.oldTouchPoint.y;
                float newX = self.theTextField.center.x;
                float newY = self.theTextField.center.y;
                
                // Check for edge cases
                int edgeX = roundf(self.theTextField.frame.origin.x + dx);
                int edgeY = roundf(self.theTextField.frame.origin.y + dy);
                
                if (edgeX > 0) {
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
                
                // Set oldTouchPoint
                self.oldTouchPoint = newTouchPoint;
                break;
            }
            default:
                break;
        }
    }
}

- (void) tapGestureDidTap: (UITapGestureRecognizer *) sender{

    if (sender.state == UIGestureRecognizerStateEnded)
    {
        // Get the touch point from the sender
        CGPoint newTouchPoint = [sender locationInView:self.theImageView];
        
        // Handle drawing a point
        if (self.isDrawing) {
            
        }
        // Handle text creation
        else {
            newTouchPoint.x = self.theImageView.center.x;
            if (self.theTextField.isHidden) {
                [self.theTextField setCenter:newTouchPoint];
                [self.theTextField setHidden:NO];
                [self.theTextField setEnabled:YES];
                [self.theTextField becomeFirstResponder];
                [UIView animateWithDuration:0.06 animations:^{
                    [self.theTextField setBackgroundColor:self.textBackgroundColor];
                }];
            } else if ([self.theTextField.text length] == 0) {
                [UIView animateWithDuration:0.06 animations:^{
                    [self.theTextField setBackgroundColor:[UIColor clearColor]];
                }];
                [self.theTextField setHidden:YES];
                [self.theTextField setEnabled:NO];
            }
        }
    }
}

//#pragma mark - UITableViewDataSource
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
//    
//    // Boilerplate for table views
//    static NSString *CellIdentifier = @"Cell";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//    }
//    
//    // Add the appropriate font name to the cell
//    UIFont *font = [self.fontArray objectAtIndex:indexPath.row];
//    cell.textLabel.text = font.fontName;
//    cell.textLabel.font = font;
//    
//    return cell;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
//    return self.fontArray.count;
//}
//
//#pragma mark - UITableViewDelegate
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    // Change the font of the text field
//    self.theTextField.font = [self.fontArray objectAtIndex:indexPath.row];
//}

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

- (IBAction)drawButtonPressed:(id)sender {
    if (self.isDrawing) {
        self.isDrawing = NO;
    } else {
        self.isDrawing = YES;
    }
}

- (IBAction)textButtonPressed:(id)sender {
    self.currentFontIndex++;
    self.currentFontIndex %= self.fontArray.count;
    [self.theTextField setFont:[self.fontArray objectAtIndex:self.currentFontIndex]];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField{
    [self.theTextField resignFirstResponder];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {    
    NSMutableString *newString = [[NSMutableString alloc] initWithString:textField.text];
    [newString replaceCharactersInRange:range withString:string];
    
    CGFloat width =  [newString sizeWithAttributes:@{NSFontAttributeName:textField.font}].width;
    
    return (textField.frame.origin.x + width < self.theImageView.frame.size.width);
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
