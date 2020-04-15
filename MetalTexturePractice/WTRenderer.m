//
//  WTRenderer.m
//  MetalTexturePractice
//
//  Created by WeiTing Ruan on 2020/2/10.
//  Copyright © 2020 papa. All rights reserved.
//

#import "WTRenderer.h"
#import "WTShaderType.h"
#import "AAPLImage.h"

@implementation WTRenderer
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLRenderPipelineState> _pipelineState;
    
    id<MTLTexture> _texture;
    id<MTLBuffer> _vertices;
    
    NSUInteger _numVertices;
    
    vector_uint2 _viewportSize;
}

- (instancetype)initWithMTKView:(MTKView *)mtkView
{
    self = [super init];
    if(self){
        _device = mtkView.device;
        
        static const WTVertex quadVertices[] = {
            
            // Pixel positions, Texture coordinates
            { {  1,  -1 },  { 1.f, 0.f } },
            { { -1,  -1 },  { 1.f, 1.f } },
            { { -1,   1 },  { 0.f, 1.f } },

            { {  1,  -1 },  { 1.f, 0.f } },
            { { -1,   1 },  { 0.f, 1.f } },
            { {  1,   1 },  { 0.f, 0.f } },
        };
        
        _vertices = [_device newBufferWithBytes:quadVertices
                                         length:sizeof(quadVertices)
                                        options:MTLResourceStorageModeShared];
        _numVertices = sizeof(quadVertices) / sizeof(WTVertex);
        
        //NSURL *imageFileLocation = [[NSBundle mainBundle] URLForResource:@"Image" withExtension:@"tga"];
        
        //_texture = [self loadTextureUsingAAPLImage: imageFileLocation];
        
        // Load the shaders from the default library
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"samplingShader"];

        // Set up a descriptor for creating a pipeline state object
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Texturing Pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;

        NSError *error = NULL;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:&error];

        NSAssert(_pipelineState, @"Failed to created pipeline state, error %@", error);

        _commandQueue = [_device newCommandQueue];
        
    }
    return self;
}

- (void)drawInMTKView:(MTKView *)view
{
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if(renderPassDescriptor != nil && _texture){
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";
        
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y}];
        
        [renderEncoder setRenderPipelineState:_pipelineState];
        
        [renderEncoder setVertexBuffer:_vertices offset:0 atIndex:WTVertexInputIndexVertices];
        
        [renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:WTVertexInputIndexViewportSize];
        
        [renderEncoder setFragmentTexture:_texture atIndex:WTTexttureIndexBaseColor];
        
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
        
        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
        NSLog(@"GPU completed");
        self->_texture = nil;
    }];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

- (void)setNewCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    _commandQueue = commandQueue;
}

- (void)renderTexture:(id<MTLTexture>)texture
{
    _texture = texture;
}

- (id<MTLTexture>)loadTextureUsingAAPLImage: (NSURL *) url {
    
    AAPLImage * image = [[AAPLImage alloc] initWithTGAFileAtLocation:url];
    
    NSAssert(image, @"Failed to create the image from %@", url.absoluteString);

    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    
    // Indicate that each pixel has a blue, green, red, and alpha channel, where each channel is
    // an 8-bit unsigned normalized value (i.e. 0 maps to 0.0 and 255 maps to 1.0)
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    // Set the pixel dimensions of the texture
    textureDescriptor.width = image.width;
    textureDescriptor.height = image.height;
    
    // Create the texture from the device by using the descriptor
    id<MTLTexture> texture = [_device newTextureWithDescriptor:textureDescriptor];
    
    // Calculate the number of bytes per row in the image.
    NSUInteger bytesPerRow = 4 * image.width;
    
    MTLRegion region = {
        { 0, 0, 0 },                   // MTLOrigin
        {image.width, image.height, 1} // MTLSize
    };
    
    // Copy the bytes from the data object into the texture
    [texture replaceRegion:region
                mipmapLevel:0
                  withBytes:image.data.bytes
                bytesPerRow:bytesPerRow];
    return texture;
}

@end
