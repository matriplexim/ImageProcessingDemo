//
//  GrayscaleSinglePassPipeline.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 14.02.2026.
//

import Metal

final class GrayscaleSinglePassPipeline {
    // MARK: Private properties
    private let context: GPUContext
    private let grayscalePass: GrayscaleComputePass

    // MARK: Initialization
    init(context: GPUContext) throws {
        self.context = context
        self.grayscalePass = try GrayscaleComputePass(context: context)
    }

    // MARK: Internal methods
    func makeTextureRequirements(width: Int, height: Int) -> [PipelineTextureRequirement] {
        [
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
        textureSet: PipelineTextureSet
    ) throws -> MTLTexture {
        let outputTexture = textureSet.getTexture(
            options: makeOutputTextureOptions(
                width: texture.width,
                height: texture.height
            )
        )

        let encoder = try context.makeComputeEncoder(
            commandBuffer: commandBuffer
        )
        grayscalePass.encode(
            encoder,
            inputTexture: texture,
            outputTexture: outputTexture,
            subtype: .single
        )
        encoder.endEncoding()

        return outputTexture
    }
}

// MARK: - Private methods
extension GrayscaleSinglePassPipeline {
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
