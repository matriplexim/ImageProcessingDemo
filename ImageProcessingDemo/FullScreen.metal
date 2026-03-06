//
//  FullScreen.metal
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

#include <metal_stdlib>
using namespace metal;

struct OutVertex {
    float4 position [[position]];
    float2 uv;
};

vertex OutVertex fullScreenVertex(uint vertexID [[vertex_id]]) {
    constexpr float2 CLIP_SPACE[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    constexpr float2 UVS[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };

    OutVertex out;
    out.position = float4(CLIP_SPACE[vertexID], 0.0, 1.0);
    out.uv = UVS[vertexID];

    return out;
}

fragment half4 fullScreenFragment(
    OutVertex inFrag [[stage_in]],
    texture2d<half, access::sample> input [[texture(0)]]
) {
    constexpr sampler SAMPLER(
        address::clamp_to_edge,
        filter::linear
    );

    return input.sample(SAMPLER, inFrag.uv);
}
