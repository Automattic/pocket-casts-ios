#import "SJMediaMetadataHelper.h"
#import <AVFoundation/AVFoundation.h>

#define MIN_EMBEDDED_IMAGE_SIZE 300

@implementation SJMediaMetadataHelper

+ (UIImage *)embeddedImageForFileAtPath:(NSString *)path {
    @try {
        NSMutableArray *artworkImages = [NSMutableArray array];
        NSURL *url = [NSURL fileURLWithPath:path];
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        
        NSArray *artworks = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata  withKey:AVMetadataCommonKeyArtwork keySpace:AVMetadataKeySpaceCommon];
        for (AVMetadataItem *metadataItem in artworks){
            NSString *keySpace = metadataItem.keySpace;
            UIImage *embeddedImage = nil;
            
            if ([keySpace isEqualToString:AVMetadataKeySpaceID3]){
                NSData *imageData = nil;
                if ([metadataItem.value isKindOfClass:[NSDictionary class]]){
                    imageData = [((NSDictionary *)metadataItem.value) objectForKey:@"data"];
                }
                else if ([metadataItem.value isKindOfClass:[NSData class]]){
                    imageData = (NSData *)metadataItem.value;
                }
                else {
                    continue; //no idea what format this is in
                }
                
                if ([SJMediaMetadataHelper isValidEmbeddedImage:imageData]){
                    embeddedImage = [UIImage imageWithData:imageData];
                }
            }
            else if ([keySpace isEqualToString:AVMetadataKeySpaceiTunes]){
                NSData *imageData = (NSData *)metadataItem.value;
                if ([SJMediaMetadataHelper isValidEmbeddedImage:imageData]){
                    embeddedImage = [UIImage imageWithData:imageData];
                }
            }
            
            if (embeddedImage) [artworkImages addObject:embeddedImage];
        }
        
        if ([artworkImages count] == 0) return nil;
        
        UIImage *biggestImage = nil;
        
        if ([artworkImages count] == 1){
            biggestImage = [artworkImages firstObject];
        }
        else {
            for (UIImage *image in artworkImages){
                if (!biggestImage){
                    biggestImage = image;
                }
                else if (image.size.height > biggestImage.size.height || image.size.width > biggestImage.size.width){
                    biggestImage = image;
                }
            }
        }
        
        //images under 300px look terrible, so don't even try to load them
        return (biggestImage.size.width >= MIN_EMBEDDED_IMAGE_SIZE)? biggestImage : nil;
    }
    @catch (NSException *exception) {
        return nil;
    }
}

// looks for the start and end tags of jpg, gif and png images to see if there's an actual valid file there
#define EIGHT_MEGABYTES_IN_BYTES 1024 * 1024 * 8
+(BOOL)isValidEmbeddedImage:(NSData *)data{
    if (!data || data.length < 12 || data.length > EIGHT_MEGABYTES_IN_BYTES) return NO;

    NSInteger totalBytes = data.length;
    const unsigned char *bytes = (const unsigned char*)[data bytes];
    
    BOOL validJpeg = (bytes[0] == 0xff &&
            bytes[1] == 0xd8 &&
            bytes[totalBytes-2] == 0xff &&
            bytes[totalBytes-1] == 0xd9);
    
    if (validJpeg) return YES;
    
    BOOL validGif = (bytes[0] == 0x46 &&
                     bytes[1] == 0x49 &&
                     bytes[2] == 0x46 &&
                     bytes[totalBytes-1] == 0x3B);
    
    if (validGif) return YES;
    
    BOOL validPng = (bytes[0] == 0x89 &&
                     bytes[1] == 0x50 &&
                     bytes[2] == 0x4e &&
                     bytes[3] == 0x47 &&
                     bytes[4] == 0x0d &&
                     bytes[5] == 0x0a &&
                     bytes[6] == 0x1a &&
                     bytes[7] == 0x0a &&
                     
                     bytes[totalBytes - 12] == 0x00 &&
                     bytes[totalBytes - 11] == 0x00 &&
                     bytes[totalBytes - 10] == 0x00 &&
                     bytes[totalBytes - 9] == 0x00 &&
                     bytes[totalBytes - 8] == 0x49 &&
                     bytes[totalBytes - 7] == 0x45 &&
                     bytes[totalBytes - 6] == 0x4e &&
                     bytes[totalBytes - 5] == 0x44 &&
                     bytes[totalBytes - 4] == 0xae &&
                     bytes[totalBytes - 3] == 0x42 &&
                     bytes[totalBytes - 2] == 0x60 &&
                     bytes[totalBytes - 1] == 0x82);
    
    return validPng;
}

@end
