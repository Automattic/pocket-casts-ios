#import "SJCommonUtils.h"
#include <sys/xattr.h>

@implementation SJCommonUtils

+ (NSTimeInterval)colonFormattedStringToTime:(NSString *)timeString {
    if ([timeString length] == 0) { return -1; }
    
    NSArray *parts = [timeString componentsSeparatedByString:@":"];
    if ([parts count] == 0) { return -1; }
    
    NSTimeInterval time = 0;
    NSInteger multiplier = 1;
    for (NSInteger i = [parts count] - 1; i >= 0; i--) {
        NSString *part = parts[i];
        time += [part integerValue] * multiplier;
        multiplier *= 60;
    }
    
    return time;
}

+(void)setDontBackupFlag:(NSURL*)url{
    u_int8_t b = 1;
    setxattr([[url path] fileSystemRepresentation], "com.apple.MobileBackup", &b, 1, 0, 0);
}

+(void)removeDontBackupFlag:(NSURL*)url{
    removexattr([[url path] fileSystemRepresentation], "com.apple.MobileBackup", 0);
}

+ (unsigned long long int)folderSize:(NSString *)folderPath {
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long int fileSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDictionary fileSize];
    }
    
    return fileSize;
}

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

@end
