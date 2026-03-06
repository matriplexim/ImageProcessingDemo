//
//  OptimizedVerticalGauss.metal
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

#include <metal_stdlib>
using namespace metal;

kernel void optimizedVerticalGauss(
    uint2 gridID [[thread_position_in_grid]],
    uint2 tgID   [[thread_position_in_threadgroup]],
    texture2d<float, access::read>  input  [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]]
) {
    if (gridID.x >= input.get_width() ||
        gridID.y >= input.get_height()) {
        return;
    }

    constexpr short RADIUS = 3;
    constexpr short SIZE = 2 * RADIUS + 1;
    constexpr short TILE_SIZE = 16;

    constexpr float GAUSS_1D[SIZE] = {
        0.0044,
        0.0540,
        0.2420,
        0.3992,
        0.2420,
        0.0540,
        0.0044
    };

    threadgroup float tile[TILE_SIZE + (SIZE - 1)][TILE_SIZE];

    int baseY = int(gridID.y) - int(tgID.y);
    int maxY = input.get_height() - 1;

    // Load tile + halo
    for (int i = tgID.y; i < TILE_SIZE + (SIZE - 1); i += TILE_SIZE) {
        uint y = clamp(baseY + i - RADIUS, 0, maxY);
        float value = input.read(uint2(gridID.x, y)).r;
        value = saturate(value);

        tile[i][tgID.x] = value;
    }

    threadgroup_barrier(mem_flags::mem_threadgroup);

    float sum = 0.0;

    for (int i = -RADIUS; i <= RADIUS; i++) {
        sum += tile[tgID.y + i + RADIUS][tgID.x] * GAUSS_1D[i + RADIUS];
    }

    float3 result = float3(sum);

    output.write(float4(result, 1.0), gridID);
}
