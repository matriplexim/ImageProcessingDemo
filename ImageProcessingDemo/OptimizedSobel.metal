//
//  OptimizedSobel.metal
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

#include <metal_stdlib>
using namespace metal;

kernel void optimizedSobelKernel(
    uint2 gridID [[thread_position_in_grid]],
    uint2 tgID   [[thread_position_in_threadgroup]],
    texture2d<float, access::read>   input  [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]]
) {
    if (gridID.x >= input.get_width() ||
        gridID.y >= input.get_height()) {
        return;
    }

    constexpr short TILE_SIZE = 16;
    constexpr short HALO = 1;
    constexpr short SHARED_SIZE = TILE_SIZE + (HALO * 2);

    constexpr uint ONE_NUMBER = 1;
    constexpr uint ZERO_NUMBER = 0;

    const uint maxX = max(input.get_width() - ONE_NUMBER, ONE_NUMBER);
    const uint maxY = max(input.get_height() - ONE_NUMBER, ONE_NUMBER);

    threadgroup float tile[SHARED_SIZE][SHARED_SIZE];

    uint localX = tgID.x + HALO;
    uint localY = tgID.y + HALO;

    tile[localY][localX] = input.read(gridID).r;

    // MARK: Sides
    // Left
    if (tgID.x == 0) {
        uint2 uv = uint2(max(gridID.x - 1, ZERO_NUMBER), gridID.y);
        tile[localY][localX - 1] = input.read(uv).r;
    }
    // Right
    if (tgID.x == TILE_SIZE - 1) {
        uint2 uv = uint2(min(gridID.x + 1, maxX), gridID.y);
        tile[localY][localX + 1] = input.read(uv).r;
    }
    // Up
    if (tgID.y == 0) {
        uint2 uv = uint2(gridID.x, max(gridID.y - 1, ZERO_NUMBER));
        tile[localY - 1][localX] = input.read(uv).r;
    }
    // Down
    if (tgID.y == TILE_SIZE - 1) {
        uint2 leftUV = uint2(gridID.x, min(gridID.y + 1, maxY));
        tile[localY + 1][localX] = input.read(leftUV).r;
    }

    // MARK: Corners
    // Left Up
    if (tgID.x == 0 && tgID.y == 0) {
        uint2 uv = uint2(max(gridID.x - 1, ZERO_NUMBER),
                         max(gridID.y - 1, ZERO_NUMBER));
        tile[localY - 1][localX - 1] = input.read(uv).r;
    }
    // Right Up
    if (tgID.x == TILE_SIZE - 1 && tgID.y == 0) {
        uint2 uv = uint2(min(gridID.x + 1, maxX),
                         max(gridID.y - 1, ZERO_NUMBER));
        tile[localY - 1][localX + 1] = input.read(uv).r;
    }
    // Left Down
    if (tgID.x == 0 && tgID.y == TILE_SIZE - 1) {
        uint2 uv = uint2(max(gridID.x - 1, ZERO_NUMBER),
                         min(gridID.y + 1, maxY));
        tile[localY + 1][localX - 1] = input.read(uv).r;
    }
    // Right Down
    if (tgID.x == TILE_SIZE - 1 && tgID.y == TILE_SIZE - 1) {
        uint2 uv = uint2(min(gridID.x + 1, maxX),
                         min(gridID.y + 1, maxY));
        tile[localY + 1][localX + 1] = input.read(uv).r;
    }

    threadgroup_barrier(mem_flags::mem_threadgroup);

    float edgeX = -tile[localY - 1][localX - 1] + tile[localY - 1][localX + 1] +
            -2.0 * tile[localY][localX - 1] + 2.0 * tile[localY][localX + 1] +
            -tile[localY + 1][localX - 1] + tile[localY + 1][localX + 1];

    float edgeY = -tile[localY - 1][localX - 1] - 2.0 * tile[localY - 1][localX] -
            tile[localY - 1][localX + 1] + tile[localY + 1][localX - 1] +
            2.0 * tile[localY + 1][localX] + tile[localY + 1][localX + 1];

    float magnitude = saturate((abs(edgeX) + abs(edgeY)));
    float3 result = float3(magnitude);

    output.write(float4(result, 1.0), gridID);
}
