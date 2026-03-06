//
//  SobelComputePass.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 19.01.2026.
//

import Metal

struct SobelComputePass {
    private let singlePipeline: MTLComputePipelineState
    private let naivePipeline: MTLComputePipelineState
    private let optimizedPipeline: MTLComputePipelineState

    init(context: GPUContext) throws {
        guard let singlePipeline = context.makePipeline(
            functionName: FilterType.singleSobel.functionName),
              let naivePipeline = context.makePipeline(
                functionName: FilterType.naiveSobel.functionName),
              let optimizedPipeline = context.makePipeline(
                functionName: FilterType.optimizedSobel.functionName) else {
            throw ProcessingError.pipelineCreateFailed
        }

        self.singlePipeline = singlePipeline
        self.naivePipeline = naivePipeline
        self.optimizedPipeline = optimizedPipeline
    }

    func encode(
        _ encoder: MTLComputeCommandEncoder,
        inputTexture: MTLTexture,
        outputTexture: MTLTexture,
        subtype: SobelComputePass.Subtype
    ) {
        encoder.label = makeEncoderLabel(by: subtype)
        encoder.setComputePipelineState(makeComputePipeline(by: subtype))

        encoder.setTexture(inputTexture, index: 0)
        encoder.setTexture(outputTexture, index: 1)

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

// MARK: - Private methods
extension SobelComputePass {
    private func makeEncoderLabel(by subtype: SobelComputePass.Subtype) -> String {
        switch subtype {
        case .single:
            FilterType.singleSobel.encoderLabel
        case .naive:
            FilterType.naiveSobel.encoderLabel
        case .optimized:
            FilterType.optimizedSobel.encoderLabel
        }
    }

    private func makeComputePipeline(
        by subtype: SobelComputePass.Subtype
    ) -> MTLComputePipelineState {
        switch subtype {
        case .single:
            singlePipeline
        case .naive:
            naivePipeline
        case .optimized:
            optimizedPipeline
        }
    }
}

// MARK: - Subtype
extension SobelComputePass {
    enum Subtype {
        case single
        case naive
        case optimized
    }
}
