//
//  ViewController.m
//  HardCodingDemo
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
#import "ViewController.h"
#import "VideoCapture.h"

@interface ViewController ()

@property (nonatomic, strong) VideoCapture *videoCapture;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}
- (VideoCapture *)videoCapture {
    if (!_videoCapture) {
        _videoCapture = [[VideoCapture alloc] init];
    }
    return _videoCapture;
}


- (IBAction)startCapturing:(id)sender {
    [self.videoCapture startCapturing:self.view];
}

- (IBAction)stopCapturing:(id)sender {
    [self.videoCapture stopCapturing];
}



@end
