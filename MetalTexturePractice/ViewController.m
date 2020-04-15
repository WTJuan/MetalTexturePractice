//
//  ViewController.m
//  MetalTexturePractice
//
//  Created by WeiTing Ruan on 2020/2/8.
//  Copyright © 2020 papa. All rights reserved.
//

#import "ViewController.h"
#import "WTRenderer.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@interface RenderView : MTKView

@end

@implementation RenderView

- (instancetype)initWithFrame:(CGRect)frameRect device:(id<MTLDevice>)device
{
    return self = [super initWithFrame:frameRect device:device];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [super initWithFrame:frame];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    return [super initWithCoder:coder];
}

- (void)draw
{
    [super draw];
}

@end

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>


@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *captureInput;


@property (nonatomic, strong) RenderView *mtkView;
@property (nonatomic, strong) id<MTLDevice> metalDevice;
@property (nonatomic, strong) WTRenderer *renderer;

@end

@implementation ViewController
{
    dispatch_queue_t videoCaptureQueue;
    dispatch_queue_t videoCaptureProcessQueue;
    CVMetalTextureCacheRef metalTextureCache;
    id<MTLTexture> texture;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupCamera];
    
    [self setupMetal];
    
    [_captureSession startRunning];
    
    [_renderer mtkView:_mtkView drawableSizeWillChange:_mtkView.drawableSize];
}

- (void)setupCamera
{
    videoCaptureQueue = dispatch_queue_create("videoCaptureQueue", DISPATCH_QUEUE_SERIAL);
    videoCaptureProcessQueue = dispatch_queue_create("videoCaptureProcessQueue", DISPATCH_QUEUE_SERIAL);
    
    AVCaptureDeviceDiscoverySession *deviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                                                                                                     mediaType:AVMediaTypeVideo
                                                                                                                      position:AVCaptureDevicePositionBack];
    if(deviceDiscoverySession.devices.count){
        _captureDevice = deviceDiscoverySession.devices.firstObject;
        NSError *error;
        [_captureDevice lockForConfiguration:&error];
        [_captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 30)];
        [_captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 30)];
        [_captureDevice unlockForConfiguration];
    }
   
    NSError *error;
    _captureInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    
    if(error){
        return;
    }
    
    _captureSession = [[AVCaptureSession alloc] init];
    if([_captureSession canAddInput:_captureInput]){
        [_captureSession addInput:_captureInput];
    }
    
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoDataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)}];
    [_videoDataOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
    
    if([_captureSession canAddOutput:_videoDataOutput]){
        [_captureSession addOutput:_videoDataOutput];
    }
    
    [_captureSession setSessionPreset:AVCaptureSessionPreset1920x1080];
    
    
    
}

- (void)setupMetal
{
    _metalDevice = MTLCreateSystemDefaultDevice();
    _mtkView = [[RenderView alloc] initWithFrame:self.view.bounds device:_metalDevice];
    _mtkView.preferredFramesPerSecond = 30;
    [self.view addSubview:_mtkView];
    
    _renderer = [[WTRenderer alloc] initWithMTKView:_mtkView];
    
    [_mtkView setDelegate:_renderer];
    NSDictionary *attribure = @{(id)kCVMetalTextureCacheMaximumTextureAgeKey : @(3)};
    CVReturn error = CVMetalTextureCacheCreate(kCFAllocatorDefault, (__bridge CFDictionaryRef)attribure, _metalDevice, nil, &metalTextureCache);
    if(error){
        NSLog(@"Failed to create metal texture cache");
    }
    
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"Capturing");
    CFRetain(sampleBuffer);
    dispatch_async(videoCaptureProcessQueue, ^{
        
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        size_t width = CVPixelBufferGetWidth(pixelBuffer);
        size_t height = CVPixelBufferGetHeight(pixelBuffer);
        
        
        CVMetalTextureRef cvMetalTextureRef;

        if(self->metalTextureCache != NULL){
            CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self->metalTextureCache, pixelBuffer, nil, MTLPixelFormatBGRA8Unorm, width, height, 0, &cvMetalTextureRef);
            NSLog(@"%d",status);
            dispatch_async(dispatch_get_main_queue(), ^{
                id<MTLTexture> mtlTexture = CVMetalTextureGetTexture(cvMetalTextureRef);
                [self->_renderer renderTexture:mtlTexture];
                CFRelease(cvMetalTextureRef);
            });
            //[_mtkView draw];
        }
        CFRelease(sampleBuffer);
    });
    
    
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(nonnull CMSampleBufferRef)sampleBuffer fromConnection:(nonnull AVCaptureConnection *)connection
{
    NSLog(@"drop frame");
}

@end
