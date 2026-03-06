//
//  Tonemap.metal
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 21.01.2026.
//

#include <metal_stdlib>
using namespace metal;

kernel void tonemapKernel(
    uint2 gridID [[thread_position_in_grid]],
    texture2d<float, access::read>  input  [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]]
) {
    if (gridID.x >= input.get_width() ||
        gridID.y >= input.get_height()) {
        return;
    }

    float4 color = input.read(gridID);

    color.rgb = color.rgb / (color.rgb + 1.0);
    color.rgb = pow(color.rgb, 1.0 / 2.2);

    output.write(color, gridID);
}

