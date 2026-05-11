//
//  PresentationBadGaussianBlur.metal
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 25.04.2026.
//

#include <metal_stdlib>
using namespace metal;

kernel void oldGaussian(
    texture2d<half, access::read>  input  [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    uint width = input.get_width();
    uint height = input.get_height();

    if (gid.x >= width ||
        gid.y >= height) {
        return;
    }

    int baseX = gid.x;
    int baseY = gid.y;
    int maxX = width;
    int maxY = height;

    constexpr int radius = 2;

    constexpr half gaussEdge[5][5] = {
        {1.0,  4.0,  7.0,  4.0, 1.0},
        {4.0, 16.0, 26.0, 16.0, 4.0},
        {7.0, 26.0, 41.0, 26.0, 7.0},
        {4.0, 16.0, 26.0, 16.0, 4.0},
        {1.0,  4.0,  7.0,  4.0, 1.0}
    };

    float4 sum = float4(0.0);
    float weightSum = 0.0;

    for (int ky = -radius; ky <= radius; ++ky) {
        for (int kx = -radius; kx <= radius; ++kx) {
            uint2 coord;
            coord.x = clamp(baseX + kx, 0, maxX - 1);
            coord.y = clamp(baseY + ky, 0, maxY - 1);

            half4 colorH = input.read(coord);
            half wH = gaussEdge[ky + radius][kx + radius];

            sum += float4(colorH) * float(wH);
            weightSum += float(wH);
        }
    }

    float4 result = sum / weightSum;

    output.write(result, gid);
}

constant half kGaussian[5][5] = {
    { 1.0h,  4.0h,  7.0h,  4.0h, 1.0h },
    { 4.0h, 16.0h, 26.0h, 16.0h, 4.0h },
    { 7.0h, 26.0h, 41.0h, 26.0h, 7.0h },
    { 4.0h, 16.0h, 26.0h, 16.0h, 4.0h },
    { 1.0h,  4.0h,  7.0h,  4.0h, 1.0h }
};

constant float kWeightSum = 273.0f;

kernel void _badGaussianBlurKernel(
    texture2d<half, access::read> input  [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],

    uint2 gid [[thread_position_in_grid]],
    uint2 tid [[thread_position_in_threadgroup]],
    uint2 tgid [[threadgroup_position_in_grid]]
)
{
    constexpr uint RADIUS = 2;
    constexpr uint TG_SIZE_X = 16;
    constexpr uint TG_SIZE_Y = 16;

    constexpr uint TILE_SIZE_X = TG_SIZE_X + RADIUS * 2;
    constexpr uint TILE_SIZE_Y = TG_SIZE_Y + RADIUS * 2;

    const uint width  = input.get_width();
    const uint height = input.get_height();

    threadgroup half4 tile[TILE_SIZE_Y][TILE_SIZE_X];

    int baseX = int(tgid.x * TG_SIZE_X);
    int baseY = int(tgid.y * TG_SIZE_Y);

    for (uint y = tid.y; y < TILE_SIZE_Y; y += TG_SIZE_Y) {
        for (uint x = tid.x; x < TILE_SIZE_X; x += TG_SIZE_X) {
            int globalX = baseX + int(x) - int(RADIUS);
            int globalY = baseY + int(y) - int(RADIUS);

            globalX = clamp(globalX, 0, int(width) - 1);
            globalY = clamp(globalY, 0, int(height) - 1);

            tile[y][x] = input.read(uint2(globalX, globalY));
        }
    }

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (gid.x >= width || gid.y >= height)
        return;

    uint localX = tid.x + RADIUS;
    uint localY = tid.y + RADIUS;

    float4 sum = float4(0.0);

    for (int ky = -int(RADIUS); ky <= int(RADIUS); ++ky) {
        for (int kx = -int(RADIUS); kx <= int(RADIUS); ++kx) {
            half4 pixel = tile[localY + ky][localX + kx];
            half weight = kGaussian[ky + int(RADIUS)][kx + int(RADIUS)];

            sum += float4(pixel) * float(weight);
        }
    }

    float4 result = sum / kWeightSum;

    output.write(result, gid);
}

kernel void badGaussianBlurKernel(
    texture2d<half, access::read> input  [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],

    uint2 gid [[thread_position_in_grid]],
    uint2 tid [[thread_position_in_threadgroup]],
    uint2 tgid [[threadgroup_position_in_grid]]
)
{
    constexpr uint RADIUS = 2;
    constexpr uint TG_SIZE_X = 16;
    constexpr uint TG_SIZE_Y = 16;

    constexpr uint TILE_SIZE_X = TG_SIZE_X + RADIUS * 2;
    constexpr uint TILE_SIZE_Y = TG_SIZE_Y + RADIUS * 2;

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

    const uint width  = input.get_width();
    const uint height = input.get_height();

    threadgroup half4 tile[TILE_SIZE_Y][TILE_SIZE_X];

    int baseX = int(tgid.x * TG_SIZE_X);
    int baseY = int(tgid.y * TG_SIZE_Y);

    for (uint y = tid.y; y < TILE_SIZE_Y; y += TG_SIZE_Y) {
        for (uint x = tid.x; x < TILE_SIZE_X; x += TG_SIZE_X) {
            int globalX = baseX + int(x) - int(RADIUS);
            int globalY = baseY + int(y) - int(RADIUS);

            globalX = clamp(globalX, 0, int(width) - 1);
            globalY = clamp(globalY, 0, int(height) - 1);

            tile[y][x] = input.read(uint2(globalX, globalY));
        }
    }

    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (gid.x >= width || gid.y >= height)
        return;

    uint localX = tid.x + RADIUS;
    uint localY = tid.y + RADIUS;

    float4 sum = float4(0.0);

    for (int ky = -int(RADIUS); ky <= int(RADIUS); ++ky) {
        for (int kx = -int(RADIUS); kx <= int(RADIUS); ++kx) {
            half4 pixel = tile[localY + ky][localX + kx];
            half weight = kGaussian[ky + int(RADIUS)][kx + int(RADIUS)];

            sum += float4(pixel) * float(weight);
        }
    }

    half4 result = half4(sum) / kWeightSum;
    tile[localY][localX] = result;

    threadgroup_barrier(mem_flags::mem_threadgroup);

    float sumX = 0.0;
    float sumY = 0.0;

    for (int ky = -1; ky <= 1; ky++) {
        for (int kx = -1; kx <= 1; kx++) {
            half4 pixel = tile[localY + ky][localX + kx];
            float intensity = dot(float4(pixel).rgb, LUMA_WEIGHTS);

            sumX += intensity * EDGE_X[kx + 1][ky + 1];
            sumY += intensity * EDGE_Y[kx + 1][ky + 1];
        }
    }

    float magnitude = length(float2(sumX, sumY));

    magnitude *= 0.25;
    magnitude = saturate(magnitude);
    magnitude = pow(magnitude, 1.0 / 2.2);

    float4 outputResult = float4(float3(magnitude), 1.0);

    output.write(outputResult, gid);
}
