//
//  VROpenGLNV12View.m
//  QYVR
//
//  Created by becomedragon on 2018/5/28.
//  Copyright © 2018年 iqiyivr. All rights reserved.
//

#import "VROpenGLNV12View.h"

NSString *FRAG_SHADER =
@"precision mediump float;\n"
"varying lowp vec2 tc;                      \n"
"uniform sampler2D SamplerY;            \n"
"uniform sampler2D SamplerUV;            \n"
"const float PI = 3.14159265;           \n"
"const mat3 convertMat = mat3( 1.0, 1.0, 1.0, 0.0, -0.39465, 2.03211, 1.13983, -0.58060, 0.0 );\n"
"float roundRGB(float num)\n"
"{\n"
"if(num < 0.0){return 0.0;}\n"
"else if(num > 255.0){return 255.0;}\n"
"else return num;"
"}\n"
"void main(void)                            \n"
"{                                          \n"
"vec3 yuv;                                  \n"
"yuv.x = texture2D(SamplerY, tc).r;         \n"
"yuv.y = texture2D(SamplerUV, tc).r - 0.5;   \n"
"yuv.z = texture2D(SamplerUV, tc).a - 0.5;   \n"
"vec3 color = convertMat * yuv;             \n"
"color.x=roundRGB(color.x);\n"
"color.y=roundRGB(color.y);\n"
"color.z=roundRGB(color.z);\n"
"vec4 mainColor = vec4(color,1.0);         \n"
"gl_FragColor =mainColor;                                       \n"
"}                                                              \n";

NSString *VERTEX_SHADER =
@"attribute vec4 vPosition;    \n"
"attribute vec2 a_texCoord;   \n"
"varying vec2 tc;             \n"
"void main()                  \n"
"{                            \n"
"   gl_Position = vPosition;  \n"
"   tc = a_texCoord;          \n"
"}                            \n";


//设置opengl 渲染的坐标系统[-1,-1] - [1，1]
float squareVertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
    
};
//设置纹理基本坐标[0,0] - [1,1]
float coordVertices[] = {
    0.0f, 1.0f,  //v0
    1.0f, 1.0f,  //v1
    0.0f,  0.0f, //v2
    1.0f,  0.0f, //v3
};

enum TextureType
{
    TEXY = 0,
    TEXUV,
};


@implementation VROpenGLNV12View

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self prepareGLEvn];
    return self;
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)prepareGLEvn
{
    [self configViewLayer];
    
    [self setupYUVTexture];
    
    [self loadAndComplieShader];
}

- (void)configViewLayer {
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGB565, kEAGLDrawablePropertyColorFormat,
                                    nil];
    
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    _viewScale = [UIScreen mainScreen].scale;
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_glContext];
}

- (void)setupYUVTexture
{
    if (_textureYUV[TEXY])
    {
        glDeleteTextures(2, _textureYUV);
    }
    glGenTextures(2, _textureYUV);
    if (!_textureYUV[TEXY] || !_textureYUV[TEXUV])
    {
        NSLog(@"<<<<<<<<<<<<纹理创建失败!>>>>>>>>>>>>");
        return;
    }
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXUV]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)loadAndComplieShader
{
    GLuint vertexShader = [self compileShader:VERTEX_SHADER withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:FRAG_SHADER withType:GL_FRAGMENT_SHADER];
    
    _program = glCreateProgram();
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);
    
    glLinkProgram(_program);
    
    aPositionMain = glGetAttribLocation(_program, "vPosition");
    aTexCoordMain = glGetAttribLocation(_program, "a_texCoord");
    
    glUseProgram(_program);
    
    GLint linkSuccess;
    glGetProgramiv(_program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"<<<<着色器连接失败 %@>>>", messageString);
    }
    
    //after attach & linked to program, can delete shader.
    if (vertexShader)
        glDeleteShader(vertexShader);
    if (fragmentShader)
        glDeleteShader(fragmentShader);
    
    GLuint textureUniformY = glGetUniformLocation(_program, "SamplerY");
    GLuint textureUniformUV = glGetUniformLocation(_program, "SamplerUV");
    glUniform1i(textureUniformY, 0);
    glUniform1i(textureUniformUV, 1);
}

- (GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType
{
    
    GLuint shaderHandle = glCreateShader(shaderType);
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    
    //shader length is 32bit.
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    return shaderHandle;
}

#pragma mark - 接口
- (void)displayNV12Data:(unsigned char*)yBuf uvBuf:(unsigned char*)uvBuf width:(NSInteger)w height:(NSInteger)h
{
    @synchronized(self)
    {
        [self createTexture:w height:h];
        [self destoryFrameAndRenderBuffer];
        [self createFrameAndRenderBuffer];
        
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w, h, GL_LUMINANCE, GL_UNSIGNED_BYTE, yBuf);
        
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXUV]);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w >> 1, h >> 1, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, uvBuf);
        
        [self render];
    }
    
    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
    {
        NSLog(@"GL_ERROR=======>%d\n", err);
    }
}

#pragma mark -
- (void)createTexture:(int)width height:(int)height
{
    void *blackData = malloc(width * height * 1.5);
    if(blackData)
        memset(blackData, 0x0, width * height * 1.5);
    
    [EAGLContext setCurrentContext:_glContext];
    
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, blackData);
    
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXUV]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, width >> 1, height >> 1, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, blackData + width * height);
    free(blackData);
}

- (BOOL)createFrameAndRenderBuffer
{
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_renderBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    if (![_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer])
    {
        NSLog(@"attach渲染缓冲区失败");
    }
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"创建缓冲区错误 0x%x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    return YES;
}

- (void)destoryFrameAndRenderBuffer
{
    if (_framebuffer)
    {
        glDeleteFramebuffers(1, &_framebuffer);
    }
    
    if (_renderBuffer)
    {
        glDeleteRenderbuffers(1, &_renderBuffer);
    }
    
    _framebuffer = 0;
    _renderBuffer = 0;
}

- (void)render
{
    [EAGLContext setCurrentContext:_glContext];
    CGSize size = self.bounds.size;
    glViewport(1, 1, size.width*_viewScale-2, size.height*_viewScale-2);
    
    // Update attribute values
    glEnableVertexAttribArray(aPositionMain);
    glVertexAttribPointer(aPositionMain, 2, GL_FLOAT, 0, 0, squareVertices);
    
    glEnableVertexAttribArray(aTexCoordMain);
    glVertexAttribPointer(aTexCoordMain, 2, GL_FLOAT, 0, 0, coordVertices);
    
    // Draw
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 3);
    //present
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)clearFrame
{
    [EAGLContext setCurrentContext:_glContext];
    glClearColor(1.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}
@end
