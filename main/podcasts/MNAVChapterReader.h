//
//  MNAVChapters.h
//  MNAVChapters
//
//  Created by Michael Nisi on 02.08.13.
/*
    Copyright (c) 2013-2018 Michael Nisi <michael.nisi@gmail.com>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTime.h>
#import <AVFoundation/AVFoundation.h>

@interface MNAVChapter : NSObject
@property (nonatomic, copy) NSString * _Nullable identifier;
@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, copy) NSString  * _Nullable title;
@property (nonatomic, copy) NSString * _Nullable url;
@property (nonatomic) CMTime time;
@property (nonatomic) CMTime duration;
#if !TARGET_OS_WATCH
@property (nonatomic) UIImage * _Nullable artwork;
#endif
- (BOOL)isEqualToChapter:(MNAVChapter *_Nonnull)aChapter;
- (MNAVChapter *_Nonnull)initWithTime:(CMTime)time duration:(CMTime)duration;
+ (MNAVChapter *_Nonnull)chapterWithTime:(CMTime)time duration:(CMTime)duration;
@end

@interface MNAVChapterReader : NSObject
+ (NSArray *_Nullable)chaptersFromAsset:(AVAsset *_Nullable)asset;
@end

# pragma mark - Internal

@protocol MNAVChapterReader <NSObject>
- (NSArray *_Nonnull)chaptersFromAsset:(AVAsset *_Nullable)asset;
@end

@interface MNAVChapterReaderMP3 : NSObject <MNAVChapterReader>
- (MNAVChapter *_Nonnull)chapterFromFrame:(NSData *_Nullable)data;
@end

@interface MNAVChapterReaderMP4 : NSObject <MNAVChapterReader>
@end
