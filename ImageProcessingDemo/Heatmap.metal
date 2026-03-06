//
//  Heatmap.metal
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

#include <metal_stdlib>
using namespace metal;

kernel void heatmapKernel(
    uint2 gridID [[thread_position_in_grid]],
    texture2d<float, access::read>  input  [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    texture2d<half, access::sample> lut    [[texture(2)]]
) {
    if (gridID.x >= input.get_width() ||
        gridID.y >= input.get_height()) {
        return;
    }

    constexpr sampler SAMPLER(
        address::clamp_to_edge,
        coord::normalized,
        filter::linear
    );

    const float width = lut.get_width();

    float value = input.read(gridID).r;
    value = saturate(value);
    value = (value * (width - 1.0) + 0.5) / width;

    float2 uv = float2(value, 0.5);
    float4 color = float4(lut.sample(SAMPLER, uv));

    output.write(color, gridID);
}
