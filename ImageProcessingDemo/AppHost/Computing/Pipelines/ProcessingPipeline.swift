//
//  ProcessingPipeline.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 14.02.2026.
//

import Metal

final class ProcessingPipeline {
    // MARK: Private properties
    private let context: GPUContext
    private let texturePool: TexturePool
    private let lutProvider: LUTProvider

    private let grayscalePass: GrayscaleComputePass
    private let gaussPass: GaussComputePass
    private let sobelPass: SobelComputePass
    private let heatmapPass: HeatmapComputePass
    private let tonemapPass: TonemapComputePass

    // MARK: Initialization
    init(
        context: GPUContext,
        texturePool: TexturePool,
        lutProvider: LUTProvider
    ) throws {
        self.context = context
        self.texturePool = texturePool
        self.lutProvider = lutProvider
        self.grayscalePass = try GrayscaleComputePass(context: context)
        self.gaussPass = try GaussComputePass(context: context)
        self.sobelPass = try SobelComputePass(context: context)
        self.heatmapPass = try HeatmapComputePass(context: context)
        self.tonemapPass = try TonemapComputePass(context: context)
    }

    // MARK: Internal properties
    func makeTextureRequirements(width: Int, height: Int) -> [PipelineTextureRequirement] {
        [
            PipelineTextureRequirement(
                options: makeOneChannelTextureOptions(
                    width: width,
                    height: height
                ),
                count: 3
            ),
            PipelineTextureRequirement(
                options: make16FloatTextureOptions(
                    width: width,
                    height: height
                ),
                count: 1
            ),
            PipelineTextureRequirement(
                options: makeOutputTextureOptions(
                    width: width,
                    height: height
                ),
                count: 1
            )
        ]
    }

    func encode(
        commandBuffer: MTLCommandBuffer,
        texture: MTLTexture,
        textureSet: PipelineTextureSet,
        isOptimized: Bool
    ) throws -> MTLTexture {
        let oneChannelTextureOptions = makeOneChannelTextureOptions(
            width: texture.width,
            height: texture.height
        )

        let outputTexture = textureSet.getTexture(options: makeOutputTextureOptions(
            width: texture.width,
            height: texture.height
        ))

        // Grayscale
        let oneChannelTexture = textureSet.getTexture(
            options: oneChannelTextureOptions
        )
        let grayscaleEncoder = try context.makeComputeEncoder(
            commandBuffer: commandBuffer
        )
        grayscalePass.encode(
            grayscaleEncoder,
            inputTexture: texture,
            outputTexture: oneChannelTexture,
            subtype: .default
        )
        grayscaleEncoder.endEncoding()

        // Gauss
        let gaussResultTexture = textureSet.getTexture(
            options: oneChannelTextureOptions
        )
        if isOptimized {
            let gaussTempTexture = textureSet.getTexture(
                options: oneChannelTextureOptions
            )
            let gaussTempEncoder = try context.makeComputeEncoder(
                commandBuffer: commandBuffer
            )
            gaussPass.encode(
                gaussTempEncoder,
                inputTexture: oneChannelTexture,
                outputTexture: gaussTempTexture,
                subtype: .optimizedVertical
            )
            gaussTempEncoder.endEncoding()

            let gaussEncoder = try context.makeComputeEncoder(
                commandBuffer: commandBuffer
            )
            gaussPass.encode(
                gaussEncoder,
                inputTexture: gaussTempTexture,
                outputTexture: gaussResultTexture,
                subtype: .optimizedHorizontal
            )
            gaussEncoder.endEncoding()
        } else {
            let gaussEncoder = try context.makeComputeEncoder(
                commandBuffer: commandBuffer
            )
            gaussPass.encode(
                gaussEncoder,
                inputTexture: oneChannelTexture,
                outputTexture: gaussResultTexture,
                subtype: .naive
            )
            gaussEncoder.endEncoding()
        }

        // Sobel
        let sobelEncoder = try context.makeComputeEncoder(
            commandBuffer: commandBuffer
        )
        sobelPass.encode(
            sobelEncoder,
            inputTexture: gaussResultTexture,
            outputTexture: oneChannelTexture,
            subtype: isOptimized ? .optimized : .naive
        )
        sobelEncoder.endEncoding()

        // Heatmap
        let heatmapTexture = textureSet.getTexture(
            options: make16FloatTextureOptions(
                width: texture.width,
                height: texture.height
            )
        )
        let heatmapEncoder = try context.makeComputeEncoder(
            commandBuffer: commandBuffer
        )
        heatmapPass.encode(
            heatmapEncoder,
            inputTexture: oneChannelTexture,
            outputTexture: heatmapTexture,
            lutTexture: try lutProvider.getLUTTexture()
        )
        heatmapEncoder.endEncoding()

        // Tonemap
        let tonemapEncoder = try context.makeComputeEncoder(
            commandBuffer: commandBuffer
        )
        tonemapPass.encode(
            tonemapEncoder,
            inputTexture: heatmapTexture,
            outputTexture: outputTexture
        )
        tonemapEncoder.endEncoding()

        return outputTexture
    }
}

// MARK: - Private properties
extension ProcessingPipeline {
    private func makeOneChannelTextureOptions(
        width: Int,
        height: Int
    ) -> PipelineTextureOptions {
        PipelineTextureOptions(
            width: width,
            height: height,
            pixelFormat: .r16Float
        )
    }

    private func make16FloatTextureOptions(
        width: Int,
        height: Int
    ) -> PipelineTextureOptions {
        PipelineTextureOptions(
            width: width,
            height: height,
            pixelFormat: .rgba16Float
        )
    }

    private func makeOutputTextureOptions(
        width: Int,
        height: Int
    ) -> PipelineTextureOptions {
        PipelineTextureOptions(
            width: width,
            height: height,
            pixelFormat: context.pixelFormat
        )
    }
}
