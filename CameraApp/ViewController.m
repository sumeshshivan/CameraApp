//
//  ViewController.m
//  CameraApp
//
//  Created by Sumesh on 12/06/15.
//  Copyright (c) 2015 qburst. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    
    AVCaptureSession *session;
    BOOL isRecording;
    AVCaptureDevice *captureDevice;
    AVCaptureDeviceInput *captureDeviceInput;
    AVCaptureVideoDataOutput *videoDataOutput;
    dispatch_queue_t sessionQueue;
    AVCaptureConnection *connection;
    
}
@property (weak, nonatomic) IBOutlet UIImageView *outputPhoto;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startStopButton;
@property AVCaptureVideoPreviewLayer *previewLayer;
@property(nonatomic, retain) AVCaptureStillImageOutput *stillImageOutput;

@end

@implementation ViewController

- (AVCaptureVideoOrientation)getAVCaptureVideoOrientationfromDeviceOrientation:(UIDeviceOrientation *)aDeviceOrientation {
    
    AVCaptureVideoOrientation orientation;
    
    switch ((int)aDeviceOrientation) {
        case UIDeviceOrientationPortrait:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    
    return orientation;
}




- (IBAction)startCamera:(id)sender {

        // Capture a still image
    
         
        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            
            if (imageDataSampleBuffer)
            {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [[UIImage alloc] initWithData:imageData];
                [_outputPhoto setImage:image];
                
                // Saving to Camera Roll
                [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];
            }
        }];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews]; //if you want superclass's behaviour...
    // resize your layers based on the view's new frame
    _previewLayer.frame = self.view.bounds;
}


- (void)viewDidAppear:(BOOL)animated {
    isRecording = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    // initializing session for the video capture.
    session = [[AVCaptureSession alloc] init];
    NSLog(@"Capture Session Created");
    
    // Setting video quality for the session.
    [session setSessionPreset:AVCaptureSessionPreset1280x720];
    NSLog(@"Session Preset Set");
    
    // defining capture device
    captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSLog(@"Capture device created");
    
    
    NSError *deviceError;
    // defining input device.
    captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&deviceError];
    if (deviceError) {
        NSLog(@"AVCaptureDeviceInput error");
        NSLog(@"%@",[deviceError description]);
    }
    
    // Adding the input device to the session.
    if ( [session canAddInput:captureDeviceInput] )
        [session addInput:captureDeviceInput];
    
    // preview video layer
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    [_previewLayer setFrame:CGRectMake(0, 0, rootLayer.bounds.size.width, rootLayer.bounds.size.height)];
    
    [rootLayer insertSublayer:_previewLayer atIndex:0];
    
//    Make a video data output
//    videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
//    // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
//    NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
//                                       [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//    [videoDataOutput setVideoSettings:rgbOutputSettings];
//    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked
//    
//    [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    
    
    
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [_stillImageOutput setOutputSettings:outputSettings];
    
    [session addOutput:_stillImageOutput];
    
    connection = [_stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //Set landscape (if required)
    if ([connection isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = [self getAVCaptureVideoOrientationfromDeviceOrientation:(UIDeviceOrientation *)[[UIDevice currentDevice] orientation]];
        [connection setVideoOrientation:orientation];
    }
    
    [session startRunning];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)orientationChanged:(NSNotification *)notification{
    AVCaptureVideoOrientation orientation = [self getAVCaptureVideoOrientationfromDeviceOrientation:(UIDeviceOrientation *)[[UIDevice currentDevice] orientation]];
    [connection setVideoOrientation:orientation];
    _previewLayer.connection.videoOrientation = [self getAVCaptureVideoOrientationfromDeviceOrientation:(UIDeviceOrientation *)[[UIDevice currentDevice] orientation]];
}

- (void)setStatusBarHidden:(BOOL)hidden
             withAnimation:(UIStatusBarAnimation)animation {
    YES;
}

@end
