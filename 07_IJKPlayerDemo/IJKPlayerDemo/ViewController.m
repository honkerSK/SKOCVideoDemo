//
//  ViewController.m
//  IJKPlayerDemo
//
//  Created by sunke on 2020/9/9.
//  Copyright © 2020 KentSun. All rights reserved.
//

/*
 1.IJKMediaFramework 拖入项目,
 2.项目General -> Framework,Libraies, and Embedded Content, 添加 libz.tbd
 3.build settings -> 搜索 header search paths -> 添加相对路径 $(SRCROOT)/IJKPlayerDemo
 
 */

#import "ViewController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>

@interface ViewController ()
@property (nonatomic, strong) IJKFFMoviePlayerController *ijkPlayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //直播拉流rtmp
    //NSURL *url = [NSURL URLWithString:@"rtmp://37.82.127.40:1935/live/demo"];
    
    NSURL *url = [NSURL URLWithString:@"http://keonline.shanghai.liveplay.qq.com/live/program/live/yxfy/1300000/mnf.m3u8"];

    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    [options setOptionIntValue:2 forKey:@"videotoolbox" ofCategory:kIJKFFOptionCategoryPlayer];

    self.ijkPlayer = [[IJKFFMoviePlayerController alloc] initWithContentURL:url withOptions:options];
    self.ijkPlayer.view.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.ijkPlayer.view.frame = self.view.bounds;

//    self.ijkPlayer.scalingMode = MPMovieScalingModeAspectFit; //缩放模式
    self.ijkPlayer.shouldAutoplay = true;//开启自动播放
    
    self.view.autoresizesSubviews = true;
    [self.view addSubview:self.ijkPlayer.view];
    
    
}

- (void)viewWillAppear:(BOOL)animated{
    [self.ijkPlayer prepareToPlay];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.ijkPlayer shutdown]; //关闭播放器
}



//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    [self.ijkPlayer prepareToPlay];
//}


@end
