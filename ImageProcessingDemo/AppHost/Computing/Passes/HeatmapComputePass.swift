//
//  HeatmapComputePass.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 18.01.2026.
//

import Metal

final class HeatmapComputePass {
    private let type: FilterType = .heatmap
    private let pipeline: MTLComputePipelineState

    init(context: GPUContext) throws {
        guard let pipeline = context.makePipeline(functionName: type.functionName) else {
            throw ProcessingError.pipelineCreateFailed
        }

        self.pipeline = pipeline
    }

    func encode(
        _ encoder: MTLComputeCommandEncoder,
        inputTexture: MTLTexture,
        outputTexture: MTLTexture,
        lutTexture: MTLTexture
    ) {
        encoder.label = type.encoderLabel
        encoder.setComputePipelineState(pipeline)

        encoder.setTexture(inputTexture, index: 0)
        encoder.setTexture(outputTexture, index: 1)
        encoder.setTexture(lutTexture, index: 2)

        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroupCount = MTLSize(
            width: (inputTexture.width  + threadGroupSize.width  - 1) / threadGroupSize.width,
            height: (inputTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )

        encoder.dispatchThreadgroups(
            threadGroupCount,
            threadsPerThreadgroup: threadGroupSize
        )
    }
}
