#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SJCommonUtils : NSObject

+ (NSTimeInterval)colonFormattedStringToTime:(NSString * _Nonnull)timeString;

+ (unsigned long long int)folderSize:(NSString * _Nonnull)folderPath;

+ (void)setDontBackupFlag:(NSURL * _Nonnull)url;
+ (void)removeDontBackupFlag:(NSURL * _Nonnull)url;

+ (BOOL)catchException:(void(^_Nullable)(void))tryBlock error:(__autoreleasing NSError  * _Nullable * _Nullable)error;

@end
