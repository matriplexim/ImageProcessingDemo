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

    func prepareResources(inputTexture: MTLTexture) async {
        var requirements: [PipelineTextureRequirement] = []

        let grayscaleTextureOptions = PipelineTextureOptions(
            width: inputTexture.width,
            height: inputTexture.height,
            pixelFormat: .r16Float
        )
        let outputTextureOptions = PipelineTextureOptions(
            width: inputTexture.width,
            height: inputTexture.height,
            pixelFormat: .bgra8Unorm
        )

        requirements.append(PipelineTextureRequirement(
            options: grayscaleTextureOptions,
            count: 1
        ))
        requirements.append(PipelineTextureRequirement(
            options: outputTextureOptions,
            count: 1
        ))

        await texturePool.prepareTextures(requirements: requirements)
    }

    func encode(
        _ encoder: MTLComputeCommandEncoder,
        texture: MTLTexture,
        textureSet: inout PipelineTextureSet,
        isOptimized: Bool
    ) async -> MTLTexture {
        let grayscaleTexture: MTLTexture
        let grayscaleTextureOptions = PipelineTextureOptions(
            width: texture.width,
            height: texture.height,
            pixelFormat: .r16Float
        )

        let outputTexture: MTLTexture
        let outputTextureOptions = PipelineTextureOptions(
            width: texture.width,
            height: texture.height,
            pixelFormat: .bgra8Unorm
        )

        if isOptimized {
            grayscaleTexture = await textureSet.getTexture(options: grayscaleTextureOptions)
            outputTexture = await textureSet.getTexture(options: outputTextureOptions)
        } else {
            grayscaleTexture = await textureSet.makeTexture(options: grayscaleTextureOptions)
            outputTexture = await textureSet.makeTexture(options: outputTextureOptions)
        }

        grayscalePass.encode(
            encoder,
            inputTexture: texture,
            outputTexture: grayscaleTexture,
            subtype: .default
        )

        sobelPass.encode(
            encoder,
            inputTexture: grayscaleTexture,
            outputTexture: outputTexture,
            subtype: isOptimized ? .optimized : .naive
        )

        return outputTexture
    }
}
