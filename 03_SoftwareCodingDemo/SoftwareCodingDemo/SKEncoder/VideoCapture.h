//
//  VideoCapture.h
//  SoftwareCodingDemo
//
//  Created by sunke on 2020/9/9.
//  Copyright © 2020 KentSun. All rights reserved.
//
// 软编码 视频采集工具类
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoCapture : NSObject
- (void)startCapturing:(UIView *)preView;
- (void)stopCapturing;
@end

NS_ASSUME_NONNULL_END
