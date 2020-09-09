//
//  ViewController.m
//  SoftwareDecodingDemo
//
//  Created by sunke on 2020/9/9.
//  Copyright © 2020 KentSun. All rights reserved.
//

/*
集成步骤:
1.将编译好的FFmpeg-iOS 文件夹拖入到工程中
2.添加依赖库: libiconv.tbd/ libz.tbd/ libbz2.tbd
3.build settings -> 搜索 header search paths -> 添加相对路径 $(SRCROOT)/SoftwareCodingDemo/FFmpeg-iOS/include
4.build settings-> Enable Bitcode 设置为NO
*/
#import "ViewController.h"
#import "avformat.h"
#import "avcodec.h"
#import "OpenGLView20.h"

@interface ViewController ()
{
    AVFormatContext *pFormatCtx; //格式上下文
    AVStream *pStream;    //视频流
    AVCodecContext *pCodecCtx; //解码上下文
    AVCodec *pCodec; //解码器
    AVFrame *pFrame;
    AVPacket packet;
    int video_index; //视频在流数组的索引
}

@property (nonatomic, strong) OpenGLView20 *glView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.glView = [[OpenGLView20 alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:self.glView atIndex:0];
    
    // 1.注册所有的格式和编码器
    av_register_all();
    
    // 2.获取文件所在的目录
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"story.mp4" ofType:nil];
    if (avformat_open_input(&pFormatCtx, [filePath UTF8String], NULL, NULL) < 0) {
        NSLog(@"打开输入流失败");
        return;
    }
    
    // 3.从AVFormatContext中查找AVStream
    if (avformat_find_stream_info(pFormatCtx, NULL) < 0) {
        NSLog(@"查找AVStream失败");
        return;
    }
    
    // 4.取出AVStream视频流信息
    video_index = -1;
    //nb_streams 记录流的个数
    for (int i = 0; i < pFormatCtx->nb_streams; i++) {
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_index = i;
            break;
        }
    }
    //保存视频流
    pStream = pFormatCtx->streams[video_index];
    
    // 5.取出解码上下文
    pCodecCtx = pStream->codec;
    
    // 6.查找解码器
    // 6.1.获取解码器
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    if (pCodec == NULL) {
        NSLog(@"查找解码器失败");
        return;
    }
    
    // 6.2.打开解码器
    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        NSLog(@"打开解码器失败");
        return;
    }
    
    // 7.创建AVFrame
    pFrame = av_frame_alloc();
}

- (IBAction)playBtnClick:(id)sender {
    while (av_read_frame(pFormatCtx, &packet) >= 0) {
        if (packet.stream_index == video_index) {
            int got_picture = -1;
            if (avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, &packet) < 0) {
                //解码失败
                continue;
            }
            
            if (got_picture) {
                // 申请内存空间
                char *buf = (char *)malloc(pFrame->width * pFrame->height * 3 / 2);
                AVPicture *pict = (AVPicture *)pFrame;//这里的frame就是解码出来的AVFrame
                int w, h, i;
                char *y, *u, *v;
                w = pFrame->width;
                h = pFrame->height;
                y = buf;  //y指向首地址
                u = y + w * h; //u 偏移y的  w*h
                v = u + w * h / 4; //v 偏移u的 w * h / 4
                for (i=0; i<h; i++)  //y
                    memcpy(y + w * i, pict->data[0] + pict->linesize[0] * i, w);
                for (i=0; i<h/2; i++) // u
                    memcpy(u + w / 2 * i, pict->data[1] + pict->linesize[1] * i, w / 2);
                for (i=0; i<h/2; i++)  //v
                    memcpy(v + w / 2 * i, pict->data[2] + pict->linesize[2] * i, w / 2);
                if (buf == NULL) {
                    continue;
                }else {
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//                        sleep(1);
                        NSLog(@"-------");
                        [self->_glView displayYUV420pData:buf width:self->pFrame -> width height:self->pFrame ->height];
                        free(buf);
                    });
                }
            }
        }
    }

}





@end
