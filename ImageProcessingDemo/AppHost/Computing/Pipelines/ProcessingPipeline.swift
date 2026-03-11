//
//  ProcessingPipeline.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 14.02.2026.
//

import Metal

final class ProcessingPipeline {
    // MARK: Private properties
    private let grayscalePass: GrayscaleComputePass
    private let gaussPass: GaussComputePass
    private let sobelPass: SobelComputePass
    private let heatmapPass: HeatmapComputePass
    private let tonemapPass: TonemapComputePass
    private let texturePool: TexturePool
    private let lutProvider: LUTProvider

    // MARK: Initialization
    init(
        context: GPUContext,
        texturePool: TexturePool,
        lutProvider: LUTProvider
    ) throws {
        self.grayscalePass = try GrayscaleComputePass(context: context)
        self.gaussPass = try GaussComputePass(context: context)
        self.sobelPass = try SobelComputePass(context: context)
        self.heatmapPass = try HeatmapComputePass(context: context)
        self.tonemapPass = try TonemapComputePass(context: context)
        self.texturePool = texturePool
        self.lutProvider = lutProvider
    }

    // MARK: Internal properties
    func prepareResources(inputTexture: MTLTexture) async {
        var requirements: [PipelineTextureRequirement] = []

        let oneChannelTextureOptions = PipelineTextureOptions(
            width: inputTexture.width,
            height: inputTexture.height,
            pixelFormat: .r16Float
        )
        let rgbaTextureOptions = PipelineTextureOptions(
            width: inputTexture.width,
            height: inputTexture.height,
            pixelFormat: .rgba16Float
        )
        let outputTextureOptions = PipelineTextureOptions(
            width: inputTexture.width,
            height: inputTexture.height,
            pixelFormat: .bgra8Unorm
        )

        requirements.append(PipelineTextureRequirement(
            options: oneChannelTextureOptions,
            count: 3
        ))
        requirements.append(PipelineTextureRequirement(
            options: rgbaTextureOptions,
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
        let oneChannelTexture: MTLTexture
        let secondOneChannelTexture: MTLTexture
        let thirdOneChannelTexture: MTLTexture
        let rgba16Texture: MTLTexture
        let outputTexture: MTLTexture

        let options = PipelineTextureOptions(
            width: texture.width,
            height: texture.height,
            pixelFormat: .r16Float
        )
        let secondOptions = PipelineTextureOptions(
            width: texture.width,
            height: texture.height,
            pixelFormat: .rgba16Float
        )
        let outputTextureOptions = PipelineTextureOptions(
            width: texture.width,
            height: texture.height,
            pixelFormat: .bgra8Unorm
        )

        if isOptimized {
            oneChannelTexture = await textureSet.getTexture(options: options)
            secondOneChannelTexture = await textureSet.getTexture(options: options)
            thirdOneChannelTexture = await textureSet.getTexture(options: options)
            rgba16Texture = await textureSet.getTexture(options: secondOptions)
            outputTexture = await textureSet.getTexture(options: outputTextureOptions)
        } else {
            oneChannelTexture = await textureSet.makeTexture(options: options)
            secondOneChannelTexture = await textureSet.makeTexture(options: options)
            thirdOneChannelTexture = await textureSet.makeTexture(options: options)
            rgba16Texture = await textureSet.makeTexture(options: secondOptions)
            outputTexture = await textureSet.makeTexture(options: outputTextureOptions)
        }

        grayscalePass.encode(
            encoder,
            inputTexture: texture,
            outputTexture: oneChannelTexture,
            subtype: .default
        )

        if isOptimized {
            gaussPass.encode(
                encoder,
                inputTexture: oneChannelTexture,
                outputTexture: secondOneChannelTexture,
                subtype: .optimizedVertical
            )

            gaussPass.encode(
                encoder,
                inputTexture: secondOneChannelTexture,
                outputTexture: thirdOneChannelTexture,
                subtype: .optimizedHorizontal
            )
        } else {
            gaussPass.encode(
                encoder,
                inputTexture: oneChannelTexture,
                outputTexture: thirdOneChannelTexture,
                subtype: .naive
            )
        }

        sobelPass.encode(
            encoder,
            inputTexture: thirdOneChannelTexture,
            outputTexture: oneChannelTexture,
            subtype: isOptimized ? .optimized : .naive
        )

        // If LUT texture doesn't ready we can handle error
        // and write one channel data to tonemap kernel.
        // It's provide opportunity to fast debug - if you see only
        // one channel result = LUT texture is not available
        do {
            heatmapPass.encode(
                encoder,
                inputTexture: oneChannelTexture,
                outputTexture: rgba16Texture,
                lutTexture: try lutProvider.getLUTTexture()
            )

            tonemapPass.encode(
                encoder,
                inputTexture: rgba16Texture,
                outputTexture: outputTexture
            )
        } catch {
            tonemapPass.encode(
                encoder,
                inputTexture: oneChannelTexture,
                outputTexture: outputTexture
            )
        }

        return outputTexture
    }
}
