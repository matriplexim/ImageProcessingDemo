//
//  SobelSinglePassPipeline.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 24.01.2026.
//

import Metal

final class SobelSinglePassPipeline {
    // MARK: Private properties
    private let context: GPUContext
    private let sobelPass: SobelComputePass

    // MARK: Initialization
    init(context: GPUContext) throws {
        self.context = context
        self.sobelPass = try SobelComputePass(context: context)
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
        sobelPass.encode(
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
extension SobelSinglePassPipeline {
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
