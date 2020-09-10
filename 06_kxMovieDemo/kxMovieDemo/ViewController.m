//
//  ViewController.m
//  kxMovieDemo
//
//  Created by sunke on 2020/9/9.
//  Copyright © 2020 KentSun. All rights reserved.
//

/*
集成步骤:
1.将编译好的FFmpeg-iOS 和 kxmovie 文件夹拖入到工程中
2.添加依赖库: libiconv.tbd/ libz.tbd/ libbz2.tbd
3.build settings -> 搜索 header search paths -> 添加相对路径 $(SRCROOT)/kxMovieDemo/FFmpeg-iOS/include
4.build settings-> Enable Bitcode 设置为NO
*/

#import "ViewController.h"
#import "KxMovieViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    ViewController *vc;
//    vc = [KxMovieViewController movieViewControllerWithContentPath:@"rtmp://47.92.137.30:1935/live/demo" parameters:nil];
    //http://keonline.shanghai.liveplay.qq.com/live/program/live/cctv5/1300000/mnf.m3u8
    vc = [KxMovieViewController movieViewControllerWithContentPath:@"http://keonline.shanghai.liveplay.qq.com/live/program/live/yxfy/1300000/mnf.m3u8" parameters:nil];
    [self presentViewController:vc animated:YES completion:nil];
}


@end
