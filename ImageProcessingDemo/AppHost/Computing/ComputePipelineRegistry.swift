//
//  ComputePipelineRegistry.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 18.01.2026.
//

import Metal

final class ComputePipelineRegistry {
    // MARK: Private properties
    private let context: GPUContext
    private let texturePool: TexturePool

    private let singleGrayscalePipeline: GrayscaleSinglePassPipeline
    private let singleSobelPipeline: SobelSinglePassPipeline
    private let singleGaussianBlurPipeline: GaussianBlurSinglePassPipeline
    private let multiPassSobelPipeline: SobelMultiPassPipeline
    private let processingPipeline: ProcessingPipeline

    // MARK: Initialization
    init(
        context: GPUContext,
        texturePool: TexturePool,
        lutProvider: LUTProvider
    ) throws {
        self.context = context
        self.texturePool = texturePool
        singleGrayscalePipeline = try GrayscaleSinglePassPipeline(context: context)
        singleSobelPipeline = try SobelSinglePassPipeline(context: context)
        singleGaussianBlurPipeline = try GaussianBlurSinglePassPipeline(context: context)
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

    // MARK: Internal methods
    func prewarm(_ texture: MTLTexture) async {
        let grayscaleRequirements = singleGrayscalePipeline.makeTextureRequirements(
            width: texture.width,
            height: texture.height
        )
        let singleSobelRequirements = singleSobelPipeline.makeTextureRequirements(
            width: texture.width,
            height: texture.height
        )
        let singleGaussianBlurRequirements = singleGaussianBlurPipeline.makeTextureRequirements(
            width: texture.width,
            height: texture.height
        )
        let multiPassRequirements = multiPassSobelPipeline.makeTextureRequirements(
            width: texture.width,
            height: texture.height
        )
        let processingRequirements = processingPipeline.makeTextureRequirements(
            width: texture.width,
            height: texture.height
        )

        await texturePool.prewarm(
            requirements: [
                grayscaleRequirements,
                singleSobelRequirements,
                singleGaussianBlurRequirements,
                multiPassRequirements,
                processingRequirements
            ].flatMap(\.self)
        )
    }

    func prepareTextureSet(
        forTexture texture: MTLTexture,
        processingType: ProcessingType
    ) async -> PipelineTextureSet {
        let textureSet = PipelineTextureSet(
            context: context,
            texturePool: texturePool
        )

        let requirements: [PipelineTextureRequirement]
        switch processingType {
        case .fullProcessing:
            requirements = processingPipeline.makeTextureRequirements(
                width: texture.width,
                height: texture.height
            )
        case .multiPassSobel:
            requirements = multiPassSobelPipeline.makeTextureRequirements(
                width: texture.width,
                height: texture.height
            )
        case .singleGrayscale:
            requirements = singleGrayscalePipeline.makeTextureRequirements(
                width: texture.width,
                height: texture.height
            )
        case .singleSobel:
            requirements = singleSobelPipeline.makeTextureRequirements(
                width: texture.width,
                height: texture.height
            )
        case .gaussianBlur:
            requirements = singleGaussianBlurPipeline.makeTextureRequirements(
                width: texture.width,
                height: texture.height
            )
        }

        await textureSet.prewarm(requirements: requirements)
        return textureSet
    }

    func encode(
        commandBuffer: MTLCommandBuffer,
        texture: MTLTexture,
        textureSet: PipelineTextureSet,
        processingType: ProcessingType,
        isOptimized: Bool
    ) throws -> MTLTexture {
        // TODO: Убрать если нужен перф без реюза текстур
        // let textureSet = PipelineTextureSet(
        //     context: context,
        //     texturePool: texturePool
        // )

        let outputTexture: MTLTexture
        switch makePassKey(by: processingType, isOptimized: isOptimized) {
        case .grayscale:
            outputTexture = try singleGrayscalePipeline.encode(
                commandBuffer: commandBuffer,
                texture: texture,
                textureSet: textureSet
            )
        case .sobel:
            outputTexture = try singleSobelPipeline.encode(
                commandBuffer: commandBuffer,
                texture: texture,
                textureSet: textureSet
            )
        case .multiPassSobel(let isOptimized):
            outputTexture = try multiPassSobelPipeline.encode(
                commandBuffer: commandBuffer,
                texture: texture,
                textureSet: textureSet,
                isOptimized: isOptimized
            )
        case .processing(let isOptimized):
            outputTexture = try processingPipeline.encode(
                commandBuffer: commandBuffer,
                texture: texture,
                textureSet: textureSet,
                isOptimized: isOptimized
            )
        case .gaussianBlur:
            outputTexture = try singleGaussianBlurPipeline.encode(
                commandBuffer: commandBuffer,
                texture: texture,
                textureSet: textureSet
            )
        }

        return outputTexture
    }
}

// MARK: - Private methods
extension ComputePipelineRegistry {
    private func makePassKey(
        by processingType: ProcessingType,
        isOptimized: Bool
    ) -> ComputePipelineRegistry.PassKey {
        switch processingType {
        case .singleGrayscale:
            return .grayscale
        case .singleSobel:
            return .sobel
        case .multiPassSobel:
            return .multiPassSobel(isOptimized: isOptimized)
        case .fullProcessing:
            return .processing(isOptimized: isOptimized)
        case .gaussianBlur:
            return .gaussianBlur
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
        case gaussianBlur
    }
}
