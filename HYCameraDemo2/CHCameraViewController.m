//
//  CHCameraViewController.m
//  HYCameraDemo2
//
//  Created by chy on 16/12/20.
//  Copyright © 2016年 Chy. All rights reserved.
//

#import "CHCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AVCamPhotoCaptureDelegate.h"
#import "HYAlbumCollection.h"
#import "HYAlbumCollectionViewCell.h"
#import "HYAlbum.h"
#import "FCAlertView.h"

static NSString * const HYCellIdentifer = @"Cell";

@interface CHCameraViewController ()
<UICollectionViewDelegate,
UICollectionViewDataSource,
FCAlertViewDelegate>

@property (nonatomic, assign) HYCameraPosition              cameraPosition;
@property (nonatomic, assign) HYCameraFlashMode             flashMode;
@property (nonatomic) dispatch_queue_t                      sessionQueue;
@property (nonatomic, strong) AVCaptureSession              *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer    *previewLayer;
@property (nonatomic, strong) AVCaptureDeviceInput          *photoInput;
@property (nonatomic, strong) AVCapturePhotoOutput          *photoOutput;
@property (nonatomic, assign) BOOL                          deviceAuthorized;
@property (nonatomic, assign) BOOL                          isCapturingImage;
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UIButton *changeDeviceButton;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UICollectionView *albumColletcionView;

@property (nonatomic) AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession;
@property (nonatomic) NSInteger inProgressLivePhotoCapturesCount;
@property (nonatomic) NSMutableDictionary<NSNumber *, AVCamPhotoCaptureDelegate *> *inProgressPhotoCaptureDelegates;
@property (nonatomic, strong) HYAlbumCollection * albumCollection;
@property (nonatomic, assign) NSInteger         seletedItem;

@end

@implementation CHCameraViewController

// MARK: - Getting methods
//--------------------------------------------------------------------

- (NSMutableDictionary *)inProgressPhotoCaptureDelegates
{
    if (_inProgressPhotoCaptureDelegates == nil) {
        _inProgressPhotoCaptureDelegates = [NSMutableDictionary dictionary];
    }
    
    return _inProgressPhotoCaptureDelegates;
}

- (HYAlbumCollection *)albumCollection
{
    if (_albumCollection == nil) {
        _albumCollection = [[HYAlbumCollection alloc] init];
    }
    
    return _albumCollection;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.seletedItem = -1;
    [self.albumColletcionView registerClass:[HYAlbumCollectionViewCell class] forCellWithReuseIdentifier:HYCellIdentifer];
    // Communicate with the session and other session objects on this queue.
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    [self _setupCaptureSession];
    [self _insertPreviewLayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self startRunning];
    
    [self _insertPreviewLayer];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self stopRunning];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _previewLayer.frame = self.view.layer.bounds;
}

#pragma mark - Capture Session Management

- (void)startRunning
{
    if (![_session isRunning]) {
        [_session startRunning];
    }
}

- (void)stopRunning
{
    if ([_session isRunning]) {
        [_session stopRunning];
    }
}

- (void)_insertPreviewLayer
{
    if (!_deviceAuthorized) {
        return;
    }
    
    if ([_previewLayer superlayer] == self.previewView.layer
        && [_previewLayer session] == _session) {
        return;
    }
    
    [self _removePreviewLayer];
    
    CALayer *layer = [self.previewView layer];
    layer.masksToBounds = YES;
    
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    _previewLayer.frame = layer.bounds;
    
    [layer insertSublayer:_previewLayer atIndex:0];
}

- (void)_removePreviewLayer
{
    [_previewLayer removeFromSuperlayer];
    _previewLayer = nil;
}

- (void)_setupCaptureSession
{
    if (_session) {
        return;
    }
    
#if !TARGET_IPHONE_SIMULATOR
    [self _checkDeviceAuthorizationWithCompletion:^(BOOL isAuthorized) {
        
        _deviceAuthorized = isAuthorized;
#else
        _deviceAuthorized = YES;
#endif
        
        if (_deviceAuthorized) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // init parameters
                _session = [AVCaptureSession new];
                _session.sessionPreset = AVCaptureSessionPresetPhoto;
                NSArray<AVCaptureDeviceType> *deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDuoCamera];
                self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
                self.inProgressLivePhotoCapturesCount = 0;
                self.flashMode = HYCameraFlashModeAuto;
                [self configFlashButton];
                
                AVCaptureDevice *device = nil;
                NSArray *devices = [AVCaptureDeviceDiscoverySession new].devices;
                for (AVCaptureDevice *currentDevice in devices) {
                    if ([currentDevice position] == [self.class _avPositionForDevice:_cameraPosition]) {
                        device = currentDevice;
                        break;
                    }
                }
                
                if (!device) {
                    device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDuoCamera mediaType:AVMediaTypeAudio position:AVCaptureDevicePositionBack];
                    if ( ! device ) {
                        // If the back dual camera is not available, default to the back wide angle camera.
                        device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
                        
                        // In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera.
                        if ( ! device ) {
                            device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
                        }
                    }
                }
                
                if ([device lockForConfiguration:nil]) {
                    if([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
                        device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
                    }
                    
                    device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            
                    [device unlockForConfiguration];
                }
                
#if !TARGET_IPHONE_SIMULATOR
                NSError *error = nil;
                AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                self.photoInput = deviceInput;
                if (deviceInput) {
                    [_session addInput:deviceInput];
                } else {
                    NSLog(@"%@", error);
                }
                
                switch (device.position) {
                    case AVCaptureDevicePositionBack:
                        _cameraPosition = HYCameraPositionBack;
                        break;
                        
                    case AVCaptureDevicePositionFront:
                        _cameraPosition = HYCameraPositionFont;
                        break;
                        
                    default:
                        break;
                }
                
#endif
                
                _photoOutput = [AVCapturePhotoOutput new];
                _photoOutput.highResolutionCaptureEnabled = YES;
                [_session addOutput:_photoOutput];
                
                if (self.isViewLoaded && self.view.window) {
                    [self startRunning];
                    [self _insertPreviewLayer];
                }
            });
        }
#if !TARGET_IPHONE_SIMULATOR
    }];
#endif
}

#pragma mark - Camera Permissions

- (void)_checkDeviceAuthorizationWithCompletion:(void (^)(BOOL isAuthorized))completion
{
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (completion) {
            completion(granted);
        }
    }];
}

// MARK: - Current device
//--------------------------------------------------------------------

+ (AVCaptureDevicePosition)_avPositionForDevice:(HYCameraPosition)cameraDevice
{
    switch (cameraDevice) {
        case HYCameraPositionFont:
            return AVCaptureDevicePositionFront;
            
        case HYCameraPositionBack:
            return AVCaptureDevicePositionBack;
            
        default:
            break;
    }
    
    return AVCaptureDevicePositionUnspecified;
}

// MARK: - Actions
//--------------------------------------------------------------------
- (IBAction)changeDevice:(id)sender {
    self.captureButton.enabled = NO;
    self.changeDeviceButton.enabled = NO;
    
    dispatch_async(self.sessionQueue, ^{
        AVCaptureDevice *currentVideoDevice = self.photoInput.device;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        
        AVCaptureDevicePosition preferredPosition;
        AVCaptureDeviceType preferredDeviceType;
        
        switch ( currentPosition )
        {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                preferredDeviceType = AVCaptureDeviceTypeBuiltInDuoCamera;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
                break;
        }
        
        NSArray<AVCaptureDevice *> *devices = self.videoDeviceDiscoverySession.devices;
        AVCaptureDevice *newVideoDevice = nil;
        
        // First, look for a device with both the preferred position and device type.
        for ( AVCaptureDevice *device in devices ) {
            if ( device.position == preferredPosition && [device.deviceType isEqualToString:preferredDeviceType] ) {
                newVideoDevice = device;
                break;
            }
        }
        
        // Otherwise, look for a device with only the preferred position.
        if ( ! newVideoDevice ) {
            for ( AVCaptureDevice *device in devices ) {
                if ( device.position == preferredPosition ) {
                    newVideoDevice = device;
                    break;
                }
            }
        }
        
        if ( newVideoDevice ) {
            AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:NULL];
            
            [self.session beginConfiguration];
            
            // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
            [self.session removeInput:self.photoInput];
            
            if ( [self.session canAddInput:videoDeviceInput] ) {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
                
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:newVideoDevice];
                
                [self.session addInput:videoDeviceInput];
                self.photoInput = videoDeviceInput;
            }
            else {
                [self.session addInput:self.photoInput];
            }
            
            AVCaptureConnection *movieFileOutputConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
            if ( movieFileOutputConnection.isVideoStabilizationSupported ) {
                movieFileOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            
            /*
             Set Live Photo capture enabled if it is supported. When changing cameras, the
             `livePhotoCaptureEnabled` property of the AVCapturePhotoOutput gets set to NO when
             a video device is disconnected from the session. After the new video device is
             added to the session, re-enable Live Photo capture on the AVCapturePhotoOutput if it is supported.
             */
            self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;
            
            [self.session commitConfiguration];
        }
        
        dispatch_async( dispatch_get_main_queue(), ^{
            self.captureButton.enabled = YES;
            self.changeDeviceButton.enabled = YES;
        } );
    });
}

- (IBAction)capturePhoto:(id)sender {
    AVCaptureVideoOrientation videoPreviewLayerVideoOrientation = self.previewLayer.connection.videoOrientation;
    dispatch_async( self.sessionQueue, ^{
        
        // Update the photo output's connection to match the video orientation of the video preview layer.
        AVCaptureConnection *photoOutputConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
        photoOutputConnection.videoOrientation = videoPreviewLayerVideoOrientation;
        
        // Capture a JPEG photo with flash set to auto and high resolution photo enabled.
        AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
        photoSettings.flashMode = [self getCurrentFlashMode];
        photoSettings.highResolutionPhotoEnabled = YES;
        if ( photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 ) {
            photoSettings.previewPhotoFormat = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject };
        }
        ///
        /// 重按活动图，不支持
        ///
        /*
        if ( self.livePhotoMode == AVCamLivePhotoModeOn && self.photoOutput.livePhotoCaptureSupported ) { // Live Photo capture is not supported in movie mode.
            NSString *livePhotoMovieFileName = [NSUUID UUID].UUIDString;
            NSString *livePhotoMovieFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[livePhotoMovieFileName stringByAppendingPathExtension:@"mov"]];
            photoSettings.livePhotoMovieFileURL = [NSURL fileURLWithPath:livePhotoMovieFilePath];
        }
         */
        
        // Use a separate object for the photo capture delegate to isolate each capture life cycle.
        HYAlbum *album = nil;
        if (self.seletedItem >= 0) {
            album = [self.albumCollection albumListShallowCopy][self.seletedItem];
        }
        AVCamPhotoCaptureDelegate *photoCaptureDelegate = [[AVCamPhotoCaptureDelegate alloc] initWithRequestedPhotoSettings:photoSettings willCapturePhotoAnimation:^{
            dispatch_async( dispatch_get_main_queue(), ^{
                self.previewLayer.opacity = 0.0;
                [UIView animateWithDuration:0.25 animations:^{
                    self.previewLayer.opacity = 1.0;
                }];
            } );
        } capturingLivePhoto:^( BOOL capturing ) {
            /*
             Because Live Photo captures can overlap, we need to keep track of the
             number of in progress Live Photo captures to ensure that the
             Live Photo label stays visible during these captures.
             */
            dispatch_async( self.sessionQueue, ^{
                if ( capturing ) {
                    self.inProgressLivePhotoCapturesCount++;
                }
                else {
                    self.inProgressLivePhotoCapturesCount--;
                }
                
                NSInteger inProgressLivePhotoCapturesCount = self.inProgressLivePhotoCapturesCount;
                dispatch_async( dispatch_get_main_queue(), ^{
                    if ( inProgressLivePhotoCapturesCount > 0 ) {
                        
                    }
                    else if ( inProgressLivePhotoCapturesCount == 0 ) {
                        
                    }
                    else {
                        NSLog( @"Error: In progress live photo capture count is less than 0" );
                    }
                } );
            } );
        } completed:^( AVCamPhotoCaptureDelegate *photoCaptureDelegate ) {
            // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
            dispatch_async( self.sessionQueue, ^{
                self.inProgressPhotoCaptureDelegates[@(photoCaptureDelegate.requestedPhotoSettings.uniqueID)] = nil;
            } );
        } album:album];
        
        /*
         The Photo Output keeps a weak reference to the photo capture delegate so
         we store it in an array to maintain a strong reference to this object
         until the capture is completed.
         */
        self.inProgressPhotoCaptureDelegates[@(photoCaptureDelegate.requestedPhotoSettings.uniqueID)] = photoCaptureDelegate;
        [self.photoOutput capturePhotoWithSettings:photoSettings delegate:photoCaptureDelegate];
    } );
}

- (IBAction)flashButtonChanged:(id)sender {
    switch (self.flashMode) {
        case HYCameraFlashModeAuto:
            self.flashMode = HYCameraFlashModeOn;
            break;
        case HYCameraFlashModeOn:
            self.flashMode = HYCameraFlashModeClose;
            break;
        case HYCameraFlashModeClose:
            self.flashMode = HYCameraFlashModeAuto;
            break;
        default:
            break;
    }
    [self configFlashButton];
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    
}

- (void)configFlashButton
{
    NSString *title = nil;
    switch (self.flashMode) {
        case HYCameraFlashModeAuto:
            title = @"Auto";
            break;
        case HYCameraFlashModeOn:
            title = @"On";
            break;
        case HYCameraFlashModeClose:
            title = @"Close";
            break;
        default:
            break;
    }
    [self.flashButton setTitle:title forState:UIControlStateNormal];
}

- (AVCaptureFlashMode)getCurrentFlashMode
{
    AVCaptureFlashMode flashMode;
    switch (self.flashMode) {
        case HYCameraFlashModeAuto:
            flashMode = AVCaptureFlashModeAuto;
            break;
        case HYCameraFlashModeOn:
            flashMode = AVCaptureFlashModeOn;
            break;
        case HYCameraFlashModeClose:
            flashMode = AVCaptureFlashModeOff;
            break;
        default:
            break;
    }
    
    return flashMode;
}

- (IBAction)addNewAlbum:(id)sender {
    FCAlertView *alertView = [[FCAlertView alloc] init];
    alertView.delegate = self;
    [alertView addTextFieldWithPlaceholder:@"相册名" andTextReturnBlock:nil];
    [alertView showAlertWithTitle:@"输入相册名" withSubtitle:nil withCustomImage:nil withDoneButtonTitle:@"取消" andButtons:@[@"确认"]];
}
- (IBAction)viewTouched:(UITapGestureRecognizer *)sender {
    CGPoint devicePoint = [self.previewLayer captureDevicePointOfInterestForPoint:[sender locationInView:sender.view]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.photoInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            /*
             Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
             Call set(Focus/Exposure)Mode() to apply the new point of interest.
             */
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}

// MARK: - FCAlertViewDelegate
//--------------------------------------------------------------------

- (void)FCAlertView:(FCAlertView *)alertView clickedButtonIndex:(NSInteger)index buttonTitle:(NSString *)title
{
    NSLog(@"button index = %ld title = %@ textReturn = %@", index, title, alertView.textField.text);
    HYAlbum *album = [[HYAlbum alloc] init];
    album.title = alertView.textField.text;
    [self.albumCollection addAlbum:album];
    [self.albumCollection archive];
    [self.albumColletcionView reloadData];
}

// MARK: - UIColletionView datasource
//--------------------------------------------------------------------

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[self.albumCollection albumListShallowCopy] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HYAlbumCollectionViewCell *cell = [self.albumColletcionView dequeueReusableCellWithReuseIdentifier:HYCellIdentifer forIndexPath:indexPath];
    HYAlbum *album = [self.albumCollection albumListShallowCopy][indexPath.item];
    BOOL isSelected = (self.seletedItem == indexPath.item);
    [cell configCellWithTitle:album.title selected:isSelected];
    
    return cell;
}

// MARK: - UICollectionView delegate
//--------------------------------------------------------------------

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item == self.seletedItem) {
        self.seletedItem = -1;
    } else {
        self.seletedItem = indexPath.row;
    }
    
    [self.albumColletcionView reloadData];
}

@end
