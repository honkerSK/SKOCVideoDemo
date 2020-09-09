//
//  ViewController.m
//  HardDecodingDemo
//
//  Created by sunke on 2020/9/9.
//  Copyright © 2020 KentSun. All rights reserved.
//

#import "ViewController.h"
#import <VideoToolbox/VideoToolbox.h>
#import "AAPLEAGLLayer.h"

@interface ViewController ()
{
    // 记录读取到的数据
    long packetSize; //读到包大小
    uint8_t *packetBuffer; //记录的指针
    
    // 定义需要的一些长度信息
    long maxReadLength; //一次最大读取的长度
    long leftLength;    //剩余长度
    uint8_t *dataPointer; //记录输入的指针
    
    // 记录sps/pps数据
    uint8_t *mSPS;
    long mSPSSize;
    uint8_t *mPPS;
    long mPPSSize;
}

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, weak) CADisplayLink *displayLink;
@property (nonatomic, strong) dispatch_queue_t queue;

///解码会话
@property (nonatomic, assign) VTDecompressionSessionRef session;
@property (nonatomic, assign) CMFormatDescriptionRef format;
@property (nonatomic, weak) AAPLEAGLLayer *previewLayer;

@end

const char startCode[] = "\x00\x00\x00\x01";
//const uint8_t startCode[4] = {0, 0, 0, 1};

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // 1.创建NSInputStream对象
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"abc.h264" ofType:nil];
    self.inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    
    // 2.定时器
    // 默认 1 60
    //  2  1 30
    //  3  1 20
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFrame)];
//    [displayLink setFrameInterval:2]; //(ios10 过期)每帧的间隔 -> 1s 30帧
    //NSInteger类型的值，用来设置间隔多少帧调用一次selector方法，默认值是1，即每帧都调用一次。(1秒=60帧)
    [displayLink setPreferredFramesPerSecond:30]; // 每秒多少帧
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [displayLink setPaused:YES];
    self.displayLink = displayLink;
    
    // 3.创建一个线程, 用于读取数据和解码数据
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // 4.创建展示的layer
    AAPLEAGLLayer *layer = [[AAPLEAGLLayer alloc] initWithFrame:self.view.bounds];
    [self.view.layer addSublayer:layer];
    self.previewLayer = layer;
}

#pragma mark - 开始读取帧
- (void)updateFrame {
    dispatch_sync(self.queue, ^{
        // 1.读取一个NALU的数据
        [self readPacket];
        
        // 2.判断是否读取到数据, 如果读的数据为NULL, 那么就直接结束
        if (packetSize == 0 || packetBuffer == NULL) {
//            [self.displayLink setPaused:YES];
//            [self.displayLink invalidate];
//            [self.inputStream close];
            [self onInputEnd];
            return;
        }
        
        // 3.根据数据的类型, 进行不同的处理
        // sps/pps/i帧/其他帧
        uint32_t nalSize = (uint32_t)(packetSize - 4);
        uint32_t *pNalSize = (uint32_t *)packetBuffer;
        *pNalSize = CFSwapInt32HostToBig(nalSize);
        // 0x27 1110 1011
        // 0x1F 0001 1111
        // 0x07 0000 1011
        int nalType = packetBuffer[4] & 0x1F;
        CVPixelBufferRef imageBuffer = NULL;
        switch (nalType) {
            case 0x07: //sps数据
                mSPSSize = packetSize - 4;
                mSPS = malloc(mSPSSize);
                memcpy(mSPS, packetBuffer + 4, mSPSSize);
                break;
            case 0x08: //pps数据
                mPPSSize = packetSize - 4;
                mPPS = malloc(mPPSSize);
                memcpy(mPPS, packetBuffer + 4, mPPSSize);
                break;
            case 0x05: //I帧数据
                [self initDecompressionSession];
                imageBuffer = [self decodeFrame];
                break;
            default: //P B帧数据
                imageBuffer = [self decodeFrame];
                break;
        }
        
        // 4.将解码出来的该帧数据, 进行展示
        if (imageBuffer != NULL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.previewLayer.pixelBuffer = imageBuffer;
                CVPixelBufferRelease(imageBuffer); // 0
            });
        }
        NSLog(@"Read Nalu size %ld", packetSize);

    });
}

/// 初始化硬解码需要的内容
- (void)initDecompressionSession {
    if(!self.session){ // 注意:没有解码会话时创建
        // 1.创建CMVideoFormatDescriptionRef
        const uint8_t *parameterSetPointers[2] = {mSPS, mPPS};
        const size_t parameterSetSizes[2] = {mSPSSize, mPPSSize};
        //创建CMVideoFormatDescription对象
        CMVideoFormatDescriptionCreateFromH264ParameterSets(NULL, 2, parameterSetPointers, parameterSetSizes, 4, &_format);
        
        // 2.解码之后的回调函数
        NSDictionary *attr = @{(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
        VTDecompressionOutputCallbackRecord callbackRecord;
        callbackRecord.decompressionOutputCallback = decompressionCallback;
        
        // 3.创建VTDecompressionSession
        VTDecompressionSessionCreate(NULL, self.format, NULL, (__bridge CFDictionaryRef _Nullable)(attr), &callbackRecord, &_session);
    }
}

/// 帧解码
- (CVPixelBufferRef)decodeFrame {
    // 1.通过之前的packetBuffer/packetSize给blockBuffer赋值
    CMBlockBufferRef blockBuffer = NULL;
    CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, (void*)packetBuffer, packetSize, kCFAllocatorNull, NULL, 0, packetSize, 0, &blockBuffer);
    
    // 2.创建准备的对象
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = {packetSize};
    CMSampleBufferCreateReady(NULL, blockBuffer, self.format, 0, 0, NULL, 0, sampleSizeArray, &sampleBuffer);
    
    // 3.开始解码
    CVPixelBufferRef outputPixelBuffer = NULL;
    VTDecompressionSessionDecodeFrame(self.session, sampleBuffer, 0, &outputPixelBuffer, NULL);
    
    // 4.释放资源
    CFRelease(sampleBuffer);
    CFRelease(blockBuffer);
    
    return outputPixelBuffer;
}

#pragma mark - 从内存中读取数据
- (void)readPacket {
    // 1.将之前保存的数据清空
    if (packetSize != 0 || packetBuffer != NULL) {
        packetSize = 0;
        free(packetBuffer);
        packetBuffer = NULL;
    }
    
    // 2.开始从文件中读取一定长度的数据 , hasBytesAvailable 有没有有效数据
    if (leftLength < maxReadLength && self.inputStream.hasBytesAvailable) {
         leftLength += [self.inputStream read:dataPointer + leftLength maxLength:maxReadLength - leftLength];
    }
    
    // 3.从dataPointer内存中取出一个NALU的长度
    // 并且放入到packetSize/packetBuffer -1
    if (memcmp(dataPointer, startCode, 4) == 0) {
        if (leftLength > 4) { // 除了开始码还有内容
            uint8_t *pStart = dataPointer + 4;
            uint8_t *pEnd = dataPointer + leftLength;
            while (pStart != pEnd) { //这里使用一种简略的方式来获取这一帧的长度：通过查找下一个0x00000001来确定。
                if(memcmp(pStart - 3, startCode, 4) == 0) { // 是开头
                    packetSize = pStart - 3 - dataPointer;
                    packetBuffer = malloc(packetSize);
                    memcpy(packetBuffer, dataPointer, packetSize); //复制packet内容到新的缓冲区
                    memmove(dataPointer, dataPointer + packetSize, leftLength - packetSize); //把缓冲区前移
                    leftLength -= packetSize;
                    break;
                } else {
                    ++pStart;
                }
            }
        }
    }
}

// CVImageBufferRef imageBuffer
// CFRelease(imageBuffer);
// 解码之后的回调函数
void decompressionCallback(void * CM_NULLABLE decompressionOutputRefCon,
                           void * CM_NULLABLE sourceFrameRefCon,
                           OSStatus status,
                           VTDecodeInfoFlags infoFlags,
                           CM_NULLABLE CVImageBufferRef imageBuffer,
                           CMTime presentationTimeStamp,
                           CMTime presentationDuration ) {
    CVPixelBufferRef *pointer = (CVPixelBufferRef *)sourceFrameRefCon;
    *pointer = CVBufferRetain(imageBuffer);
}

- (IBAction)play:(id)sender {
    // 1.对定义的长度进行赋值
    maxReadLength = 720 * 1280;
    leftLength = 0;
    dataPointer = malloc(maxReadLength);
    
    // 2.打开文件
    [self.inputStream open];
    
    // 3.开始读取
    [self.displayLink setPaused:NO];
}


- (void)onInputEnd {
    [self.inputStream close];
    self.inputStream = nil;
    if (dataPointer) {
        free(dataPointer);
        dataPointer = NULL;
    }
    [self.displayLink setPaused:YES];
    
    [self EndVideoToolBox];
}

- (void)EndVideoToolBox{
    VTDecompressionSessionInvalidate(_session);
    CFRelease(_session);
    
    CFRelease(_format);
    _format = NULL;
    
    free(mSPS);
    free(mPPS);
    mSPSSize = mPPSSize = 0;
    
    [self.previewLayer removeFromSuperlayer];
}

@end
