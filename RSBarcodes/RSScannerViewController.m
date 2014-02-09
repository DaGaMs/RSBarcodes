//
//  RSScannerViewController.m
//  RSBarcodes
//
//  Created by R0CKSTAR on 12/19/13.
//  Copyright (c) 2013 P.D.Q. All rights reserved.
//

#import "RSScannerViewController.h"
#import "RSCornersView.h"


@interface RSScannerViewController () <AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) UIImage *capturedImage;
@end

NSString const *RSScannerCaptureErrorNoSource = @"RSScannerCaptureErrorNoSource";

@implementation RSScannerViewController

#pragma mark - Private

- (void)__applicationWillEnterForeground:(NSNotification *)notification
{
    [self __startRunning];
}

- (void)__applicationDidEnterBackground:(NSNotification *)notification
{
    [self __stopRunning];
}

- (void)__handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer
{
    CGPoint tapPoint = [tapGestureRecognizer locationInView:self.view];
    CGPoint focusPoint= CGPointMake(tapPoint.x / self.view.bounds.size.width, tapPoint.y / self.view.bounds.size.height);
    
    if (!self.device) {
        return;
    } else if ([self.device lockForConfiguration:nil]) {
        if ([self.device isFocusPointOfInterestSupported])
            [self.device setFocusPointOfInterest:focusPoint];

        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
        
        if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance])
            [self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];

        if ([self.device isExposurePointOfInterestSupported])
            [self.device setExposurePointOfInterest:focusPoint];

        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose])
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];

        [self.device unlockForConfiguration];
        
        if (self.isFocusMarkVisible) {
            self.highlightView.focusPoint = tapPoint;
        }
        
        if (self.tapGestureHandler) {
            self.tapGestureHandler(tapPoint);
        }
    }
}

- (void)__setup
{
    self.isCornersVisible = YES;
    self.isBorderRectsVisible = NO;
    self.isFocusMarkVisible = YES;
    
    if (self.session) {
        return;
    }
    
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!self.device) {
        NSLog(@"No video camera on this device!");
        return;
    }
    
    if ([self.device lockForConfiguration:nil]) {
        if ([self.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
            [self.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
            [self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        if ([self.device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
            [self.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        [self.device unlockForConfiguration];
    }
    
    self.session = [[AVCaptureSession alloc] init];
    NSError *error = nil;
    self.input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:&error];
    if (error) {
        NSLog(@"%@", error);
        return;
    }
    
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    self.layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.layer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.layer];
    
    self.output = [[AVCaptureMetadataOutput alloc] init];
    dispatch_queue_t queue = dispatch_queue_create("com.pdq.RSBarcodes.metadata", 0);
    [self.output setMetadataObjectsDelegate:self queue:queue];
    if ([self.session canAddOutput:self.output]) {
        [self.session addOutput:self.output];
        self.output.metadataObjectTypes = @[AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode128Code,AVMetadataObjectTypeCode39Code];
    } else {
        NSLog(@"ERROR: can't add metadata capture output");
    }
    
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    if ([self.session canAddOutput:self.imageOutput]) {
        [self.session addOutput:self.imageOutput];
    } else {
        NSLog(@"ERROR: can't add image capture output");
    }
    
    [self.view bringSubviewToFront:self.highlightView];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(__handleTapGesture:)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    tapGestureRecognizer.delegate = self;
}

- (void)__startRunning
{
    if (self.session.isRunning) {
        return;
    }
    
    [self.session startRunning];
    
    // reset settings to autofocus and auto-whitebalance
    if (self.device && [self.device lockForConfiguration:nil]) {
        if ([self.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
            [self.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
            [self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        if ([self.device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
            [self.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        [self.device unlockForConfiguration];
    }
}

- (void)__stopRunning {
    if (!self.session.isRunning) {
        return;
    }
    
    [self.session stopRunning];
}

#pragma mark GestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    NSLog(@"Other recogniser: %@",otherGestureRecognizer);
    return YES;
}

#pragma mark - Action
- (void)captureImageOnCompletion:(void (^)(UIImage *, NSError *))completionBlock
{
    AVCaptureConnection *videoConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if (!videoConnection)
    {
        NSError *error = [NSError errorWithDomain:RSScannerCaptureErrorNoSource
                                             code:RSScannerCaptureErrorCodeNoSource
                                         userInfo:nil];
        completionBlock(nil, error);
        return;
    }
    
    NSLog(@"about to request a capture from: %@", self.imageOutput);
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        // WARNING we're back on the main thread!
        if (error) {
            completionBlock(nil, error);
        }
        else if (imageSampleBuffer != NULL) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            UIImage *capturedImage = [UIImage imageWithData:imageData];
            completionBlock(capturedImage, nil);
        } else {
            NSError *error = [NSError errorWithDomain:@"No image data"
                                                 code:RSScannerCaptureErrorCodeNoData
                                             userInfo:nil];
            completionBlock(nil, error);
        }
    }];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self __setup];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(__applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(__applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [self __startRunning];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    
    [self __stopRunning];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSMutableArray *barcodeObjects  = nil;
    NSMutableArray *cornersArray    = nil;
    NSMutableArray *borderRectArray = nil;
    
    for (AVMetadataObject *metadataObject in metadataObjects) {
        AVMetadataObject *transformedMetadataObject = [self.layer transformedMetadataObjectForMetadataObject:metadataObject];
        if ([transformedMetadataObject isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            AVMetadataMachineReadableCodeObject *barcodeObject = (AVMetadataMachineReadableCodeObject *)transformedMetadataObject;
            if (!barcodeObjects) {
                barcodeObjects = [[NSMutableArray alloc] init];
            }
            [barcodeObjects addObject:barcodeObject];
            
            if (self.isCornersVisible) {
                if ([barcodeObject respondsToSelector:@selector(corners)]) {
                    if (!cornersArray) {
                        cornersArray = [[NSMutableArray alloc] init];
                    }
                    [cornersArray addObject:barcodeObject.corners];
                }
            }
            
            if (self.isBorderRectsVisible) {
                if ([barcodeObject respondsToSelector:@selector(bounds)]) {
                    if (!borderRectArray) {
                        borderRectArray = [[NSMutableArray alloc] init];
                    }
                    [borderRectArray addObject:[NSValue valueWithCGRect:barcodeObject.bounds]];
                }
            }
        }
    }
    
    if (self.isCornersVisible) {
        self.highlightView.cornersArray = cornersArray ? [NSArray arrayWithArray:cornersArray] : nil;
    }
    
    if (self.isBorderRectsVisible) {
        self.highlightView.borderRectArray = borderRectArray ? [NSArray arrayWithArray:borderRectArray] : nil;
    }
    
    if (self.barcodesHandler) {
        self.barcodesHandler([NSArray arrayWithArray:barcodeObjects]);
    }
}

@end
