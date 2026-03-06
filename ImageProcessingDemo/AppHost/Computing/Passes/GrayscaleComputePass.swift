//
//  GrayscaleComputePass.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 18.01.2026.
//

import Metal

struct GrayscaleComputePass {
    private let defaultPipeline: MTLComputePipelineState
    private let singlePipeline: MTLComputePipelineState

    init(context: GPUContext) throws {
        guard let defaultPipeline = context.makePipeline(
            functionName: FilterType.grayscale.functionName),
              let singlePipeline = context.makePipeline(
                functionName: FilterType.singleGrayscale.functionName) else {
            throw ProcessingError.pipelineCreateFailed
        }

        self.defaultPipeline = defaultPipeline
        self.singlePipeline = singlePipeline
    }

    func encode(
        _ encoder: MTLComputeCommandEncoder,
        inputTexture: MTLTexture,
        outputTexture: MTLTexture,
        subtype: GrayscaleComputePass.Subtype
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
extension GrayscaleComputePass {
    private func makeEncoderLabel(by subtype: GrayscaleComputePass.Subtype) -> String {
        switch subtype {
        case .default:
            FilterType.grayscale.encoderLabel
        case .single:
            FilterType.singleGrayscale.encoderLabel
        }
    }

    private func makeComputePipeline(
        by subtype: GrayscaleComputePass.Subtype
    ) -> MTLComputePipelineState {
        switch subtype {
        case .default:
            defaultPipeline
        case .single:
            singlePipeline
        }
    }
}

// MARK: - Subtype
extension GrayscaleComputePass {
    enum Subtype {
        case `default`
        case single
    }
}
