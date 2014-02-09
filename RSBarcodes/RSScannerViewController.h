//
//  RSScannerViewController.h
//  RSBarcodes
//
//  Created by R0CKSTAR on 12/19/13.
//  Copyright (c) 2013 P.D.Q. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef enum RSScannerErrorCode {
    RSScannerCaptureErrorCodeNoSource = 1,
    RSScannerCaptureErrorCodeNoData
} RSScannerErrorCode;

extern NSString const *RSScannerCaptureErrorNoSource;

@class RSCornersView;

typedef void (^RSBarcodesHandler)(NSArray *barcodeObjects);

typedef void (^RSTapGestureHandler)(CGPoint tapPoint);

@interface RSScannerViewController : UIViewController <UIGestureRecognizerDelegate>


@property (nonatomic, strong) NSArray *barcodeObjectTypes;
@property (nonatomic, weak) IBOutlet RSCornersView *highlightView;
@property (nonatomic, copy) RSBarcodesHandler barcodesHandler;
@property (nonatomic, copy) RSTapGestureHandler tapGestureHandler;
@property (nonatomic) BOOL isCornersVisible;     // Default is YES
@property (nonatomic) BOOL isBorderRectsVisible; // Default is NO
@property (nonatomic) BOOL isFocusMarkVisible;   // Default is YES

// expose internals so that children can modify the settings
@property (nonatomic, strong) AVCaptureSession           *session;
@property (nonatomic, strong) AVCaptureDevice            *device;
@property (nonatomic, strong) AVCaptureDeviceInput       *input;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *layer;
@property (nonatomic, strong) AVCaptureMetadataOutput    *output;
@property (nonatomic, strong) AVCaptureStillImageOutput  *imageOutput;

- (void)captureImageOnCompletion:(void(^)(UIImage *capturedImage, NSError *error))completionBlock;

@end
