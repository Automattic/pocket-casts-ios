#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SJMediaMetadataHelper : NSObject

+ (UIImage * _Nullable)embeddedImageForFileAtPath:(NSString * _Nonnull)path;
+(BOOL)isValidEmbeddedImage:(NSData *_Nullable)data;
@end
