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
        inputTexture: MTLTexture,
        outputTexture: MTLTexture
    ) {
        grayscalePass.encode(
            encoder: encoder,
            inputTexture: inputTexture,
            outputTexture: outputTexture,
            subtype: .single
        )
    }
}
