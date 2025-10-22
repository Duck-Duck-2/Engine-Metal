//
//  triangle.metal
//  Engine Metal
//
//  Created by Max Shi on 10/21/25.
//

// metal library
#include <metal_stdlib>

// the vertex_id is the vertex number so we know which vertex information to use
// constant simd::float3* is the vertexPositions array pointer of 3d vectors
// constant means it's in read-only memory
vertex float4 vertexShader(uint vertexID [[vertex_id]], constant simd::float3* vertexPositions) {
    float4 vertexOutPositions = float4(vertexPositions[vertexID], 1.0f);
    return vertexOutPositions;
}

// stage_in means that this parameter should be received from the vertex buffer
fragment float4 fragmentShader(float4 vertexOutPositions [[stage_in]]) {
    return float4(182.0f/255.0f, 240.0f/255.0f, 228.0f/255.0f, 1.0f);
}
