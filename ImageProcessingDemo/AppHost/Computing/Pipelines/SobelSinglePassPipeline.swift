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
        inputTexture: MTLTexture,
        outputTexture: MTLTexture
    ) {
        sobelPass.encode(
            encoder,
            inputTexture: inputTexture,
            outputTexture: outputTexture,
            subtype: .single
        )
    }
}
