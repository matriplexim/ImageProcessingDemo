//
//  SobelOptimizedPipeline.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 24.01.2026.
//

import Metal

final class SobelMultiPassPipeline {
    private let grayscalePass: GrayscaleComputePass
    private let sobelPass: SobelComputePass
    private let texturePool: TexturePool

    init(context: GPUContext, texturePool: TexturePool) throws {
        self.grayscalePass = try GrayscaleComputePass(context: context)
        self.sobelPass = try SobelComputePass(context: context)
        self.texturePool = texturePool
    }

    func prepareResources(inputTexture: MTLTexture) {
        var requirements: [PipelineTextureRequirement] = []
        let grayscaleTextureOptions = PipelineTextureOptions(
            width: inputTexture.width,
            height: inputTexture.height,
            pixelFormat: .r16Float
        )
        requirements.append(PipelineTextureRequirement(
            options: grayscaleTextureOptions,
            count: 1
        ))

        texturePool.prepareTextures(requirements: requirements)
    }

    func encode(
        _ encoder: MTLComputeCommandEncoder,
        inputTexture: MTLTexture,
        outputTexture: MTLTexture,
        textureSet: inout PipelineTextureSet,
        isOptimized: Bool
    ) {
        let grayscaleTexture: MTLTexture
        let options = PipelineTextureOptions(
            width: inputTexture.width,
            height: inputTexture.height,
            pixelFormat: .r16Float
        )

        if isOptimized {
            grayscaleTexture = textureSet.getTexture(options: options)
        } else {
            grayscaleTexture = textureSet.makeTexture(options: options)
        }

        grayscalePass.encode(
            encoder,
            inputTexture: inputTexture,
            outputTexture: grayscaleTexture,
            subtype: .default
        )

        sobelPass.encode(
            encoder,
            inputTexture: grayscaleTexture,
            outputTexture: outputTexture,
            subtype: isOptimized ? .optimized : .naive
        )
    }
}
