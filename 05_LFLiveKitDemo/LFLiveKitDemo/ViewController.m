//
//  ViewController.m
//  LFLiveKitDemo
//
//  Created by sunke on 2020/9/9.
//  Copyright © 2020 KentSun. All rights reserved.
//
// 推流 LFLiveKit
//LFLiveKit是一个集成了视频采集-美颜-编码-推流为一体的框架,并且使用起来非常的简单, 我们可以在iOS中直接使用该框架进行推流

#import "ViewController.h"
//#import <LFLiveKit.h>
#import "LFLiveKit.h"

@interface ViewController () <LFLiveSessionDelegate>
@property (nonatomic, strong) LFLiveSession *session;

@end

@implementation ViewController

- (LFLiveSession*)session {
    if (!_session) {
        _session = [[LFLiveSession alloc] initWithAudioConfiguration:[LFLiveAudioConfiguration defaultConfiguration] videoConfiguration:[LFLiveVideoConfiguration defaultConfiguration]];
        _session.preView = self.view;
        _session.delegate = self;
    }
    return _session;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)startLive:(id)sender {
    
    LFLiveStreamInfo *streamInfo = [LFLiveStreamInfo new];
    streamInfo.url = @"rtmp://57.82.116.40/live/demo"; //推流地址
    self.session.running = YES;
    [self.session startLive:streamInfo];
}

- (IBAction)stopLive:(id)sender {
    [self.session stopLive];

}


//MARK: - CallBack:
- (void)liveSession:(nullable LFLiveSession *)session liveStateDidChange: (LFLiveState)state {
    NSLog(@"%lu", (unsigned long)state);
}
- (void)liveSession:(nullable LFLiveSession *)session debugInfo:(nullable LFLiveDebug*)debugInfo {
    NSLog(@"%@", debugInfo);
}
- (void)liveSession:(nullable LFLiveSession*)session errorCode:(LFLiveSocketErrorCode)errorCode {
    NSLog(@"%lu", (unsigned long)errorCode);
}


@end
