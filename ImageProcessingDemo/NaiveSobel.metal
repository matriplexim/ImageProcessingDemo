//
//  NaiveSobel.metal
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

#include <metal_stdlib>
using namespace metal;

kernel void naiveSobelKernel(
    uint2 gridID [[thread_position_in_grid]],
    texture2d<float, access::sample> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]]
) {
    if (gridID.x >= input.get_width() ||
        gridID.y >= input.get_height()) {
        return;
    }

    constexpr float3 LUMA_WEIGHTS = float3(0.299, 0.587, 0.114);

    constexpr short EDGE_X[3][3] = {
        { -1, 0, 1 },
        { -2, 0, 2 },
        { -1, 0, 1 }
    };

    constexpr short EDGE_Y[3][3] = {
        { -1, -2, -1 },
        {  0,  0,  0 },
        {  1,  2,  1 }
    };

    constexpr sampler SAMPLER(
        address::clamp_to_edge,
        coord::pixel,
        filter::nearest
    );

    float sumX = 0.0;
    float sumY = 0.0;

    float2 baseCoord = float2(gridID);

    for (int ky = -1; ky <= 1; ky++) {
        for (int kx = -1; kx <= 1; kx++) {
            float4 color = input.sample(SAMPLER, baseCoord + float2(kx, ky));
            float intensity = dot(color.rgb, LUMA_WEIGHTS);

            sumX += intensity * EDGE_X[kx + 1][ky + 1];
            sumY += intensity * EDGE_Y[kx + 1][ky + 1];
        }
    }

    float magnitude = abs(sumX) + abs(sumY);
    magnitude = saturate(magnitude);

    float3 result = float3(magnitude);

    output.write(float4(result, 1.0), gridID);
}
