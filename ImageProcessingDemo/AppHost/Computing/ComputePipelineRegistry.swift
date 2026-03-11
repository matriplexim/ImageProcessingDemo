//
//  ComputePipelineRegistry.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 18.01.2026.
//

import Metal

final class ComputePipelineRegistry {
    private let singleGrayscalePipeline: GrayscaleSinglePassPipeline
    private let singleSobelPipeline: SobelSinglePassPipeline
    private let multiPassSobelPipeline: SobelMultiPassPipeline
    private let processingPipeline: ProcessingPipeline

    init(
        context: GPUContext,
        texturePool: TexturePool,
        lutProvider: LUTProvider
    ) throws {
        singleGrayscalePipeline = try GrayscaleSinglePassPipeline(context: context)
        singleSobelPipeline = try SobelSinglePassPipeline(context: context)
        multiPassSobelPipeline = try SobelMultiPassPipeline(
            context: context,
            texturePool: texturePool
        )
        processingPipeline = try ProcessingPipeline(
            context: context,
            texturePool: texturePool,
            lutProvider: lutProvider
        )
    }

    func prepareByTexture(_ texture: MTLTexture) async {
        await multiPassSobelPipeline.prepareResources(inputTexture: texture)
        await processingPipeline.prepareResources(inputTexture: texture)
    }

    func encode(
        _ encoder: MTLComputeCommandEncoder,
        key: ComputePipelineRegistry.PassKey,
        texture: MTLTexture,
        textureSet: inout PipelineTextureSet
    ) async -> MTLTexture {
        switch key {
        case .grayscale:
            await singleGrayscalePipeline.encode(
                encoder,
                texture: texture,
                textureSet: &textureSet
            )
        case .sobel:
            await singleSobelPipeline.encode(
                encoder,
                texture: texture,
                textureSet: &textureSet
            )
        case .multiPassSobel(let isOptimized):
            await multiPassSobelPipeline.encode(
                encoder,
                texture: texture,
                textureSet: &textureSet,
                isOptimized: isOptimized
            )
        case .processing(let isOptimized):
            await processingPipeline.encode(
                encoder,
                texture: texture,
                textureSet: &textureSet,
                isOptimized: isOptimized
            )
        }
    }
}

// MARK: - Key
extension ComputePipelineRegistry {
    enum PassKey {
        case grayscale
        case sobel
        case multiPassSobel(isOptimized: Bool)
        case processing(isOptimized: Bool)
    }
}
