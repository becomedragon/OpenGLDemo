//
//  VROpenGLNV12View.h
//  QYVR
//
//  Created by becomedragon on 2018/5/28.
//  Copyright © 2018年 iqiyivr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>
#include <sys/time.h>

@interface VROpenGLNV12View : UIView
{
    /**
     OpenGL绘图上下文
     */
    EAGLContext             *_glContext;
    
    /**
     帧缓冲区
     */
    GLuint                  _framebuffer;
    
    /**
     渲染缓冲区
     */
    GLuint                  _renderBuffer;
    
    /**
     着色器句柄
     */
    GLuint                  _program;
    
    /**
     YUV纹理数组
     */
    GLuint                  _textureYUV[2];
    
    /**
     视频宽度
     */
    GLuint                  _videoW;
    
    /**
     视频高度
     */
    GLuint                  _videoH;
    
    GLsizei                 _viewScale;
    
    GLuint aPositionMain;
    GLuint aTexCoordMain;
    //void                    *_pYuvData;
    
#ifdef DEBUG
    struct timeval      _time;
    NSInteger           _frameRate;
#endif
}
#pragma mark - 接口
- (void)displayNV12Data:(unsigned char*)yBuf uvBuf:(unsigned char*)uvBuf width:(NSInteger)w height:(NSInteger)h;

/**
 清除画面
 */
- (void)clearFrame;

@end
