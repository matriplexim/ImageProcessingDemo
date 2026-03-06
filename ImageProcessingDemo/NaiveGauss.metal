//
//  NaiveGauss.metal
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

#include <metal_stdlib>
using namespace metal;

kernel void naive2DGaussKernel(
    uint2 gridID [[thread_position_in_grid]],
    texture2d<float, access::read>  input  [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]]
) {
    if (gridID.x >= input.get_width() ||
        gridID.y >= input.get_height()) {
        return;
    }

    constexpr short RADIUS = 2;
    constexpr short SIZE = 2 * RADIUS + 1;

    constexpr float GAUSS[SIZE][SIZE] = {
        {0.0008, 0.0066, 0.0133, 0.0066, 0.0008},
        {0.0066, 0.0549, 0.1109, 0.0549, 0.0066},
        {0.0133, 0.1109, 0.2231, 0.1109, 0.0133},
        {0.0066, 0.0549, 0.1109, 0.0549, 0.0066},
        {0.0008, 0.0066, 0.0133, 0.0066, 0.0008}
    };

    int maxX = input.get_width() - 1;
    int maxY = input.get_height() - 1;

    int baseX = gridID.x;
    int baseY = gridID.y;

    float sum = 0.0;

    for (int y = -RADIUS; y <= RADIUS; y++) {
        for (int x = -RADIUS; x <= RADIUS; x++) {
            uint2 coord;
            coord.x = clamp(baseX + x, 0, maxX);
            coord.y = clamp(baseY + y, 0, maxY);

            float weight = GAUSS[y + RADIUS][x + RADIUS];
            float value = input.read(coord).r;
            value = saturate(value);

            sum += value * weight;
        }
    }

    float3 result = float3(sum);

    output.write(float4(result, 1.0), gridID);
}
