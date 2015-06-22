//
//  ViewController.m
//  CameraApp
//
//  Created by Sumesh on 12/06/15.
//  Copyright (c) 2015 qburst. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    
    BOOL isRecording;
    AVCaptureSession *session;
    AVCaptureDevice *captureDevice;
    AVCaptureDeviceInput *captureDeviceInput;
    AVCaptureVideoDataOutput *videoDataOutput;
    dispatch_queue_t sessionQueue;
    AVCaptureConnection *connection;
    NSURL *documentsURL;
    NSURL *outputURL;
    
}
@property (weak, nonatomic) IBOutlet UIImageView *outputPhoto;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startStopButton;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, retain) AVCaptureMovieFileOutput *videoOutput;

@end

@implementation ViewController

// Returns Capture Video Orientation from given Device Orientation
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


// Sets up initial configurations for a Capture session
- (void)setCaptureConfigurations {
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
    
    // set preview layer frame with root layer's values.
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    [_previewLayer setFrame:CGRectMake(0, 0, rootLayer.bounds.size.width, rootLayer.bounds.size.height)];
    
    // add preview layer to root layer
    [rootLayer insertSublayer:_previewLayer atIndex:0];
}



- (NSURL*)grabFileURL:(NSString *)fileName {
    
    // find Documents directory
    documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    // append a file name to it
    documentsURL = [documentsURL URLByAppendingPathComponent:fileName];
    
    return documentsURL;
}


- (IBAction)startCamera:(id)sender {
    
    if (!isRecording) {
        _startStopButton.tintColor = [UIColor redColor];

//        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
//        outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        outputURL = [self grabFileURL:@"output.mov"];
        [_videoOutput stopRecording];
        
        [_videoOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        
    } else {
        _startStopButton.tintColor = [UIColor blueColor];
        [_videoOutput stopRecording];
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        [assetLibrary writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
            if(error == nil){
                // Saved successfully
                NSLog(@"success");
                NSLog(@"%@",assetURL);
            }
        }];

    }
    
    isRecording = !isRecording;
    
        // Capture a still image
    
//        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
//            
//            if (imageDataSampleBuffer)
//            {
//                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
//                UIImage *image = [[UIImage alloc] initWithData:imageData];
//                [_outputPhoto setImage:image];
//                
//                // Saving to Camera Roll
//                [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];
//            }
//        }];
    
}

-(void)viewWillAppear:(BOOL)animated {
//    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];
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

    [self setCaptureConfigurations];
    
    //Set landscape (if required)
    _videoOutput = [[AVCaptureMovieFileOutput alloc] init];
    [session addOutput:_videoOutput];
    AVCaptureVideoOrientation avcaptureOrientation = AVCaptureVideoOrientationLandscapeLeft;
    [connection setVideoOrientation:avcaptureOrientation];
    if ([connection isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = [self getAVCaptureVideoOrientationfromDeviceOrientation:(UIDeviceOrientation *)[[UIDevice currentDevice] orientation]];
        [connection setVideoOrientation:orientation];
    }
    AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeLeft;
    [connection setVideoOrientation:orientation];
    [session startRunning];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)orientationChanged:(NSNotification *)notification{
//    AVCaptureVideoOrientation orientation = [self getAVCaptureVideoOrientationfromDeviceOrientation:(UIDeviceOrientation *)[[UIDevice currentDevice] orientation]];
//    [connection setVideoOrientation:orientation];
//    _previewLayer.connection.videoOrientation = [self getAVCaptureVideoOrientationfromDeviceOrientation:(UIDeviceOrientation *)[[UIDevice currentDevice] orientation]];
//}

- (void)setStatusBarHidden:(BOOL)hidden
             withAnimation:(UIStatusBarAnimation)animation {
    YES;
}


-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    
}
@end
