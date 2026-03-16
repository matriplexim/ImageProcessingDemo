//
//  SobelOptimizedPipeline.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 24.01.2026.
//

import Metal

final class SobelMultiPassPipeline {
    // MARK: Private properties
    private let context: GPUContext
    private let texturePool: TexturePool
    private let grayscalePass: GrayscaleComputePass
    private let sobelPass: SobelComputePass

    // MARK: Initialization
    init(context: GPUContext, texturePool: TexturePool) throws {
        self.context = context
        self.texturePool = texturePool
        self.grayscalePass = try GrayscaleComputePass(context: context)
        self.sobelPass = try SobelComputePass(context: context)
    }

    // MARK: Internal methods
    func makeTextureRequirements(width: Int, height: Int) -> [PipelineTextureRequirement] {
        [
            PipelineTextureRequirement(
                options: makeOneChannelOptions(
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
        let oneChannelTexture = textureSet.getTexture(
            options: makeOneChannelOptions(
                width: texture.width,
                height: texture.height
            )
        )

        let outputTexture = textureSet.getTexture(
            options: makeOutputTextureOptions(
                width: texture.width,
                height: texture.height
            )
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

        let sobelEncoder = try context.makeComputeEncoder(
            commandBuffer: commandBuffer
        )
        sobelPass.encode(
            sobelEncoder,
            inputTexture: oneChannelTexture,
            outputTexture: outputTexture,
            subtype: isOptimized ? .optimized : .naive
        )
        sobelEncoder.endEncoding()

        return outputTexture
    }
}

// MARK: - Private properties
extension SobelMultiPassPipeline {
    private func makeOneChannelOptions(
        width: Int,
        height: Int
    ) -> PipelineTextureOptions {
        PipelineTextureOptions(
            width: width,
            height: height,
            pixelFormat: .r16Float
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
