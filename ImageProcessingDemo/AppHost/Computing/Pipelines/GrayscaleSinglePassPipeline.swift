//
//  GrayscaleSinglePassPipeline.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 14.02.2026.
//

import Metal

final class GrayscaleSinglePassPipeline {
    private let grayscalePass: GrayscaleComputePass

    init(context: GPUContext) throws {
        self.grayscalePass = try GrayscaleComputePass(context: context)
    }

    func encode(
        _ encoder: MTLComputeCommandEncoder,
        texture: MTLTexture,
        textureSet: inout PipelineTextureSet
    ) async -> MTLTexture {
        let outputTextureOptions = PipelineTextureOptions(
            width: texture.width,
            height: texture.height,
            pixelFormat: .bgra8Unorm
        )
        let outputTexture = await textureSet.getTexture(options: outputTextureOptions)

        grayscalePass.encode(
            encoder,
            inputTexture: texture,
            outputTexture: outputTexture,
            subtype: .single
        )

        return outputTexture
    }
}
