/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Photo capture delegate.
*/

#import "AVCamPhotoCaptureDelegate.h"
#import "HYAlbum.h"

@import Photos;

@interface AVCamPhotoCaptureDelegate ()

@property (nonatomic, readwrite) AVCapturePhotoSettings *requestedPhotoSettings;
@property (nonatomic) void (^willCapturePhotoAnimation)();
@property (nonatomic) void (^capturingLivePhoto)(BOOL capturing);
@property (nonatomic) void (^completed)(AVCamPhotoCaptureDelegate *photoCaptureDelegate);

@property (nonatomic) NSData *photoData;
@property (nonatomic) NSURL *livePhotoCompanionMovieURL;

@property (nonatomic, strong) HYAlbum *album;

@end

@implementation AVCamPhotoCaptureDelegate

- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)requestedPhotoSettings
                     willCapturePhotoAnimation:(void (^)())willCapturePhotoAnimation
                            capturingLivePhoto:(void (^)(BOOL))capturingLivePhoto
                                     completed:(void (^)(AVCamPhotoCaptureDelegate *))completed
                                         album:(HYAlbum *)album
{
	self = [super init];
	if ( self ) {
		self.requestedPhotoSettings = requestedPhotoSettings;
		self.willCapturePhotoAnimation = willCapturePhotoAnimation;
		self.capturingLivePhoto = capturingLivePhoto;
		self.completed = completed;
        self.album = album;
	}
	return self;
}

- (void)didFinish
{
	if ( [[NSFileManager defaultManager] fileExistsAtPath:self.livePhotoCompanionMovieURL.path] ) {
		NSError *error = nil;
		[[NSFileManager defaultManager] removeItemAtPath:self.livePhotoCompanionMovieURL.path error:&error];
		
		if ( error ) {
			NSLog( @"Could not remove file at url: %@", self.livePhotoCompanionMovieURL.path );
		}
	}
	
	self.completed( self );
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
	if ( ( resolvedSettings.livePhotoMovieDimensions.width > 0 ) && ( resolvedSettings.livePhotoMovieDimensions.height > 0 ) ) {
		self.capturingLivePhoto( YES );
	}
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
	self.willCapturePhotoAnimation();
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error
{
	if ( error != nil ) {
		NSLog( @"Error capturing photo: %@", error );
		return;
	}
	
	self.photoData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
	self.capturingLivePhoto(NO);
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error
{
	if ( error != nil ) {
		NSLog( @"Error processing live photo companion movie: %@", error );
		return;
	}
	
	self.livePhotoCompanionMovieURL = outputFileURL;
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error
{
	if ( error != nil ) {
		NSLog( @"Error capturing photo: %@", error );
		[self didFinish];
		return;
	}
	
	if ( self.photoData == nil ) {
		NSLog( @"No photo data resource" );
		[self didFinish];
		return;
	}
	
	[PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
		if ( status == PHAuthorizationStatusAuthorized ) {
            if (self.album) {
                [self saveImageToAlbume:self.photoData];
            } else {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
                    [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:self.photoData options:nil];
                    
                    if ( self.livePhotoCompanionMovieURL ) {
                        PHAssetResourceCreationOptions *livePhotoCompanionMovieResourceOptions = [[PHAssetResourceCreationOptions alloc] init];
                        livePhotoCompanionMovieResourceOptions.shouldMoveFile = YES;
                        [creationRequest addResourceWithType:PHAssetResourceTypePairedVideo fileURL:self.livePhotoCompanionMovieURL options:livePhotoCompanionMovieResourceOptions];
                    }
                } completionHandler:^( BOOL success, NSError * _Nullable error ) {
                    if ( ! success ) {
                        NSLog( @"Error occurred while saving photo to photo library: %@", error );
                    }
                    
                    [self didFinish];
                }];
            }
		}
		else {
			NSLog( @"Not authorized to save photo" );
			[self didFinish];
		}
	}];
}

//保存照片至本地相册
-(void)saveImageToAlbume:(NSData*)data
{
    UIImage *image = [UIImage imageWithData:data];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHPhotoLibrary* photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
        [photoLibrary performChanges:^{
            PHFetchResult* fetchCollectionResult;
            PHAssetCollectionChangeRequest* collectionRequest;
            if(self.album.isDocCreated){
                fetchCollectionResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[self.album.ID] options:nil];
                PHAssetCollection* exisitingCollection = fetchCollectionResult.firstObject;
                collectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:exisitingCollection];
            } else {
                fetchCollectionResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[self.album.title] options:nil];
                // Create a new album
                if (!fetchCollectionResult || fetchCollectionResult.count == 0 ){
                    collectionRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:self.album.title];
                    self.album.isDocCreated = YES;
                }
            }
            PHAssetChangeRequest* createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            [collectionRequest addAssets:@[createAssetRequest.placeholderForCreatedAsset]];
        } completionHandler:^(BOOL success, NSError *error){
            if (error) {
                NSLog(@"error:%@",error);
            }
        }];
    });
}

@end
