//
//  SobelSinglePassPipeline.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 24.01.2026.
//

import Metal

final class SobelSinglePassPipeline {
    private let sobelPass: SobelComputePass

    init(context: GPUContext) throws {
        self.sobelPass = try SobelComputePass(context: context)
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

        sobelPass.encode(
            encoder,
            inputTexture: texture,
            outputTexture: outputTexture,
            subtype: .single
        )

        return outputTexture
    }
}
