//
//  H264Encoder.h
//  SoftwareCodingDemo
//
//  Created by sunke on 2020/9/9.
//  Copyright © 2020 KentSun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface H264Encoder : NSObject
/// 准备编码
/// @param width 视频宽度
/// @param height 视频高度
- (void)prepareEncodeWithWidth:(int)width height:(int)height;
/// 开始编码
- (void)encodeFrame:(CMSampleBufferRef)sampleBuffer;
/// 结束编码
- (void)endEncoding;

@end

NS_ASSUME_NONNULL_END
