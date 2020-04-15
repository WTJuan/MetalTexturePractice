//
//  WTRenderer.h
//  MetalTexturePractice
//
//  Created by WeiTing Ruan on 2020/2/10.
//  Copyright © 2020 papa. All rights reserved.
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface WTRenderer : NSObject <MTKViewDelegate>

- (instancetype)initWithMTKView:(MTKView *)mtkView;
- (void)renderTexture:(id<MTLTexture>)texture;
- (void)setNewCommandQueue:(id<MTLCommandQueue>)commandQueue;

@end
