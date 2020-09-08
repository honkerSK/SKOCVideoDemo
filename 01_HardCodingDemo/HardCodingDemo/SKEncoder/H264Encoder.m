//
//  H264Encoder.m
//  HardCodingDemo
//
//  Created by sunke on 2020/9/9.
//  Copyright © 2020 KentSun. All rights reserved.
//

#import "H264Encoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface H264Encoder()
{
    int frameIndex;
}

@property (nonatomic, assign) VTCompressionSessionRef session;
@property (nonatomic, strong) NSFileHandle *fileHandle;

@end

@implementation H264Encoder

- (void)prepareEncodeWithWidth:(int)width height:(int)height {
    // 创建文件
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"abc.h264"];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    
    // 0.定义帧的下标值
    frameIndex = 0;
    
    // 1.创建VTCompressionSessionRef对象
    // 参数一: CoreFoundation创建对象的方式, NULL -> Default
    // 参数二: 编码的视频的宽度
    // 参数三: 编码的视频的高度
    // 参数四: 编码的标准 H.264/H/265
    // 参数五~参数七 : NULL
    // 参数八: 编码成功一帧数据后的回调函数
    // 参数九: 回调函数中的第一个参数
    VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, compressCallback, (__bridge void * _Nullable)(self), &_session);
    
    // 2.设置VTCompressionSessionRef属性
    // 2.1.如果只直播, 需要设置视频编码是实时输出
    // 帧/s
    VTSessionSetProperty(self.session, kVTCompressionPropertyKey_RealTime, (__bridge CFTypeRef _Nonnull)(@YES));
    
    // 2.2.设置帧率(16/24/30)
    VTSessionSetProperty(self.session, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef _Nonnull)(@30));
    
    // 2.3.设置比特率(码率) bit/s
    VTSessionSetProperty(self.session, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef _Nonnull)(@1500000)); // bit
    NSArray *limits = (@[@(1500000/8), @1]); // byte
    VTSessionSetProperty(_session, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFTypeRef _Nonnull)(limits));
    
    // 2.4.设置GOP的大小
    VTSessionSetProperty(self.session, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef _Nonnull)(@20));
    
    // 3.准备开始编码
    VTCompressionSessionPrepareToEncodeFrames(self.session);
}

- (void)encodeFrame:(CMSampleBufferRef)sampleBuffer
{
    // 1.从CMSampleBufferRef中获取CVImageBufferRef
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // 利用VTCompressionSessionRef, 编码sampleBuffer图像
    // pts(presentationTimeStamp) : 展示时间戳, 用来解码时, 计算每一帧的事件
    // dts(DecodeTimeStamp) : 解码时间戳, 决定该帧在什么时间展示
    frameIndex++;
    CMTime pts = CMTimeMake(frameIndex, 30);
    VTCompressionSessionEncodeFrame(self.session, imageBuffer, pts, kCMTimeInvalid, NULL, NULL, NULL);
}

void compressCallback(void * CM_NULLABLE outputCallbackRefCon,
              void * CM_NULLABLE sourceFrameRefCon,
              OSStatus status,
              VTEncodeInfoFlags infoFlags,
              CM_NULLABLE CMSampleBufferRef sampleBuffer) {
    
    // 1.获取当前的对象
    H264Encoder *encoder = (__bridge H264Encoder *)(outputCallbackRefCon);
    
    // 2.判断该帧是否是关键帧
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFDictionaryRef dict = CFArrayGetValueAtIndex(attachments, 0);
    BOOL isKeyFrame = !CFDictionaryContainsKey(dict, kCMSampleAttachmentKey_NotSync);
    
    // 3.如果是关键帧, 那么在将关键帧写入文件之前, 先写入SPS/PPS数据
    if (isKeyFrame) {
        // 3.1.获取参数信息
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        // 3.2.从format中获取SPS信息
        const uint8_t *spsPointer;
        size_t spsSize, spsCount;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &spsPointer, &spsSize, &spsCount, NULL);
        
        // 3.3.从format中获取PPS信息
        const uint8_t *ppsPointer;
        size_t ppsSize, ppsCount;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &ppsPointer, &ppsSize, &ppsCount, NULL);
        
        // 3.4.将sps/pps写入NAL单元
        NSData *spsData = [NSData dataWithBytes:spsPointer length:spsSize];
        NSData *ppsData = [NSData dataWithBytes:ppsPointer length:ppsSize];
        [encoder writeData:spsData];
        [encoder writeData:ppsData];
    }
    
    // 4.将编码后的帧数据写入文件中
    // 4.1.获取CMBlockBufferRef
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    
    // 4.2.CMBlockBufferRef获取到内存地址/长度
    size_t totalLength;
    char *dataPointer;
    CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &totalLength, &dataPointer);
    
    // 4.3.从dataPointer位置开始读取数据, 并且写入NALU --> slice切片
    static const int h264HeaderLegnth = 4;
    size_t offsetLength = 0;
    
    // 4.4.通过循环, 不断的读取slice的切换数据, 并且封装成NALU写入文件
    while (h264HeaderLegnth < totalLength - offsetLength) {
        // 4.5.读取slice的长度
        uint32_t naluLength;
        memcpy(&naluLength, dataPointer + offsetLength, h264HeaderLegnth);
        
        // 4.6.H264大端字节序
        naluLength = CFSwapInt32BigToHost(naluLength);
        
        // 4.7.根据读取字节, 并且转成NSData
        NSData *data = [NSData dataWithBytes:dataPointer + offsetLength + h264HeaderLegnth length:naluLength];
        
        // 4.8.写入文件
        [encoder writeData:data];
        
        // 4.9.设置offsetLength
        offsetLength += naluLength + h264HeaderLegnth;
    }
}


- (void)writeData:(NSData *)data {
    // NALU的形式写入文件
    // NALU头
    const char bytes[] = "\x00\x00\x00\x01"; // \0
    int headerLength = sizeof(bytes) - 1;
    NSData *headerData = [NSData dataWithBytes:bytes length:headerLength];
    
    // NALU体
    // 将数据写入文件
    [self.fileHandle writeData:headerData];
    [self.fileHandle writeData:data];
}

- (void)endEncoding
{
    VTCompressionSessionInvalidate(self.session);
    CFRelease(self.session);
}

@end
