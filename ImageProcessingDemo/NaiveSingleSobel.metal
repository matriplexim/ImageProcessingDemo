//
//  NaiveSingleSobel.metal
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 07.02.2026.
//

#include <metal_stdlib>
using namespace metal;

kernel void singleNaiveSobelKernel(
    uint2 gridID [[thread_position_in_grid]],
    texture2d<float, access::sample> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]]
) {
    if (gridID.x >= input.get_width() ||
        gridID.y >= input.get_height()) {
        return;
    }

    constexpr float3 LUMA = float3(0.299, 0.587, 0.114);

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

    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            float4 color = input.sample(SAMPLER, baseCoord + float2(x, y));
            float intensity = dot(color.rgb, LUMA);

            sumX += intensity * EDGE_X[y + 1][x + 1];
            sumY += intensity * EDGE_Y[y + 1][x + 1];
        }
    }

    float magnitude = length(float2(sumX, sumY));

    magnitude *= 0.25;
    magnitude = saturate(magnitude);
    magnitude = pow(magnitude, 1.0 / 2.2);

    float3 result = float3(magnitude);

    output.write(float4(result, 1.0), gridID);
}
