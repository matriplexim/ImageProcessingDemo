//
//  Grayscale.metal
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 17.01.2026.
//

#include <metal_stdlib>
using namespace metal;

kernel void grayscaleKernel(
    uint2 gridID [[thread_position_in_grid]],
    texture2d<half, access::read>   input  [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]]
) {
    if (gridID.x >= input.get_width() ||
        gridID.y >= input.get_height()) {
        return;
    }

    constexpr float3 LUMA_WEIGHTS = float3(0.299, 0.587, 0.114);

    half4 color = input.read(gridID);
    float4 fcolor = float4(color);
    float intensity = dot(fcolor.rgb, LUMA_WEIGHTS);
    intensity = saturate(intensity);

    float3 result = float3(intensity);

    output.write(float4(result, 1.0), gridID);
}
