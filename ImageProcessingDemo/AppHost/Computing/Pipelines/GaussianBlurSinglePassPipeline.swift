//
//  GaussianBlurSinglePassPipeline.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 25.04.2026.
//

import Metal

final class GaussianBlurSinglePassPipeline {
    // MARK: Private properties
    private let context: GPUContext
    private let pass: GaussComputePass

    // MARK: Initialization
    init(context: GPUContext) throws {
        self.context = context
        self.pass = try GaussComputePass(context: context)
    }

    // MARK: Internal properties
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
        pass.encode(
            encoder,
            inputTexture: texture,
            outputTexture: outputTexture,
            subtype: .benchmark
        )
        encoder.endEncoding()

        return outputTexture
    }
}

// MARK: - Private methods
extension GaussianBlurSinglePassPipeline {
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
