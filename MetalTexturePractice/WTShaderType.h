//
//  WTShaderType.h
//  MetalTexturePractice
//
//  Created by WeiTing Ruan on 2020/2/9.
//  Copyright © 2020 papa. All rights reserved.
//

#include <simd/simd.h>

typedef struct{
    
    vector_float2 position;
    vector_float2 textureCoordinate;
    
} WTVertex;

typedef enum WTVertexInputIndex
{
    WTVertexInputIndexVertices = 0,
    WTVertexInputIndexViewportSize = 1
    
} WTVertexInputIndex;

typedef enum WTTexttureIndex
{
    WTTexttureIndexBaseColor = 0
    
} WTTexttureIndex;
