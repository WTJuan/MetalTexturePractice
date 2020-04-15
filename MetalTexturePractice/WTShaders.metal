//
//  WTShaders.metal
//  MetalTexturePractice
//
//  Created by WeiTing Ruan on 2020/2/10.
//  Copyright © 2020 papa. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "WTShaderType.h"
using namespace metal;

typedef struct
{
    float4 position [[position]];
    
    float2 textureCoordinate;
    
} RasterizerData;


vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                                   constant WTVertex *vertexArray [[buffer(WTVertexInputIndexVertices)]],
                                   constant vector_uint2 *viewportSizePointer [[buffer(WTVertexInputIndexViewportSize)]])
{
    RasterizerData out;
    
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
    
    float2 viewportSize = float2(*viewportSizePointer);
    
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition;
    
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;

    return out;
}

fragment float4 samplingShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[ texture(WTTexttureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    half gray = 0.2672*colorSample.r + 0.6780 * colorSample.g + 0.0593 * colorSample.b;
    
    return float4(gray);
}
