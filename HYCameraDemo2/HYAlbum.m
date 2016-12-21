//
//  HYAlbum.m
//  HYCameraDemo2
//
//  Created by chy on 16/12/20.
//  Copyright © 2016年 Chy. All rights reserved.
//

#import "HYAlbum.h"
#import <Photos/Photos.h>

static NSString * const HYTitleKey = @"title";
static NSString * const HYIDKey = @"id";

@implementation HYAlbum

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

// MARK: - NSCoding
//--------------------------------------------------------------------

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.title forKey:HYTitleKey];
    [aCoder encodeObject:self.ID forKey:HYIDKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _title = [aDecoder decodeObjectForKey:HYTitleKey];
        _ID = [aDecoder decodeObjectForKey:HYIDKey];
    }
    
    return self;
}

-(void)saveImageToSystemAlbum:(NSData*)data
{
    UIImage *image = [UIImage imageWithData:data];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHPhotoLibrary* photoLibrary = [PHPhotoLibrary sharedPhotoLibrary];
        [photoLibrary performChanges:^{
            PHFetchResult* fetchCollectionResult;
            PHAssetCollectionChangeRequest* collectionRequest;
            if(self.ID){
                fetchCollectionResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[self.ID] options:nil];
                PHAssetCollection* exisitingCollection = fetchCollectionResult.firstObject;
                collectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:exisitingCollection];
            } else {
                fetchCollectionResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[self.title] options:nil];
                // Create a new album
                if (!fetchCollectionResult || fetchCollectionResult.count == 0 ){
                    collectionRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:self.title];
                    self.ID = collectionRequest.placeholderForCreatedAssetCollection.localIdentifier;
                }
            }
            PHAssetChangeRequest * createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            [collectionRequest addAssets:@[createAssetRequest.placeholderForCreatedAsset]];
        } completionHandler:^(BOOL success, NSError *error){
            if (error) {
                NSLog(@"error:%@",error);
            }
        }];
    });
}

@end
