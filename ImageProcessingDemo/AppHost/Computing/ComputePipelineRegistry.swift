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

    func prepareByTexture(_ texture: MTLTexture) {
        multiPassSobelPipeline.prepareResources(inputTexture: texture)
        processingPipeline.prepareResources(inputTexture: texture)
    }

    func encode(
        _ encoder: MTLComputeCommandEncoder,
        key: ComputePipelineRegistry.SinglePassKey,
        inputTexture: MTLTexture,
        outputTexture: MTLTexture
    ) {
        switch key {
        case .grayscale:
            singleGrayscalePipeline.encode(
                encoder,
                inputTexture: inputTexture,
                outputTexture: outputTexture
            )
        case .sobel:
            singleSobelPipeline.encode(
                encoder,
                inputTexture: inputTexture,
                outputTexture: outputTexture
            )
        }
    }

    func encode(
        _ encoder: MTLComputeCommandEncoder,
        key: ComputePipelineRegistry.MultiPassKey,
        inputTexture: MTLTexture,
        outputTexture: MTLTexture,
        textureSet: inout PipelineTextureSet
    ) {
        switch key {
        case .multiPassSobel(let isOptimized):
            multiPassSobelPipeline.encode(
                encoder,
                inputTexture: inputTexture,
                outputTexture: outputTexture,
                textureSet: &textureSet,
                isOptimized: isOptimized
            )
        case .processing(let isOptimized):
            processingPipeline.encode(
                encoder,
                inputTexture: inputTexture,
                outputTexture: outputTexture,
                textureSet: &textureSet,
                isOptimized: isOptimized
            )
        }
    }
}

// MARK: - Key
extension ComputePipelineRegistry {
    enum SinglePassKey {
        case grayscale
        case sobel
    }

    enum MultiPassKey {
        case multiPassSobel(isOptimized: Bool)
        case processing(isOptimized: Bool)
    }
}
