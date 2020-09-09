//
//  ViewController.m
//  SoftwareCodingDemo
//
//  Created by sunke on 2020/9/9.
//  Copyright © 2020 KentSun. All rights reserved.
//
/*
1> 创建AVCaptureSession
2> 添加输入设备
   * 摄像头 device -> position
3> 添加输出
   * AVCaptureDataVideooutput
   * 设置代理
4> 添加预览图层
   * previewLayer
5> 开始采集视频
*/

/*
 集成步骤:
 1.将编译好的FFmpeg-iOS 和 x264-iOS 文件夹拖入到工程中
 2.添加依赖库: libiconv.tbd/ libz.tbd/ libbz2.tbd
 3.build settings -> 搜索 header search paths -> 添加相对路径 $(SRCROOT)/SoftwareCodingDemo/FFmpeg-iOS/include
 4.build settings-> Enable Bitcode 设置为NO
 */

#import "ViewController.h"
#import "VideoCapture.h"

@interface ViewController ()
@property (nonatomic, strong) VideoCapture *videoCapture;

@end

@implementation ViewController

- (VideoCapture *)videoCapture {
    if (!_videoCapture) {
        _videoCapture = [[VideoCapture alloc] init];
    }
    return _videoCapture;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)startCapturing:(id)sender {
    [self.videoCapture startCapturing:self.view];
}

- (IBAction)stopCapturing:(id)sender {
    [self.videoCapture stopCapturing];
}

@end
