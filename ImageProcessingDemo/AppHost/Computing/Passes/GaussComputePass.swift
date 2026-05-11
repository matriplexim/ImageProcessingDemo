//
//  GaussComputePass.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 18.01.2026.
//

import Metal

struct GaussComputePass {
    private let context: GPUContext
    private var benchmarkPipeline: MTLComputePipelineState!
    private let naivePipeline: MTLComputePipelineState
    private let optimizedHorizontalPipeline: MTLComputePipelineState
    private let optimizedVerticalPipeline: MTLComputePipelineState

    init(context: GPUContext) throws {
        self.context = context
        let benchmarkPipeline = context.makePipeline(
            functionName: FilterType.benchmarkGaussianBlur.functionName
        )
        let naivePipeline = context.makePipeline(
            functionName: FilterType.naiveGauss.functionName
        )
        let optimizedHorizontalPipeline = context.makePipeline(
            functionName: FilterType.optimizedHorizontalGauss.functionName
        )
        let optimizedVerticalPipeline = context.makePipeline(
            functionName: FilterType.optimizedVerticalGauss.functionName
        )

        guard let naivePipeline,
              let optimizedHorizontalPipeline,
              let optimizedVerticalPipeline,
              let benchmarkPipeline else {
            throw ProcessingError.pipelineCreateFailed
        }

        self.naivePipeline = naivePipeline
        self.optimizedHorizontalPipeline = optimizedHorizontalPipeline
        self.optimizedVerticalPipeline = optimizedVerticalPipeline
        self.benchmarkPipeline = benchmarkPipeline
    }

    func encode(
        _ encoder: MTLComputeCommandEncoder,
        inputTexture: MTLTexture,
        outputTexture: MTLTexture,
        subtype: GaussComputePass.Subtype
    ) {
        let benchmarkPipeline = context.makePipeline(
            functionName: FilterType.benchmarkGaussianBlur.functionName
        )

        encoder.label = makeEncoderLabel(by: subtype)
        encoder.setComputePipelineState(benchmarkPipeline!)

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

extension GaussComputePass {
    private func makeEncoderLabel(by subtype: GaussComputePass.Subtype) -> String {
        switch subtype {
        case .naive:
            FilterType.naiveGauss.encoderLabel
        case .optimizedHorizontal:
            FilterType.optimizedHorizontalGauss.encoderLabel
        case .optimizedVertical:
            FilterType.optimizedVerticalGauss.encoderLabel
        case .benchmark:
            FilterType.benchmarkGaussianBlur.encoderLabel
        }
    }

    private func makePipelineState(
        by subtype: GaussComputePass.Subtype
    ) -> MTLComputePipelineState {
        switch subtype {
        case .naive:
            naivePipeline
        case .optimizedHorizontal:
            optimizedHorizontalPipeline
        case .optimizedVertical:
            optimizedVerticalPipeline
        case .benchmark:
            benchmarkPipeline
        }
    }
}

// MARK: - Subtype
extension GaussComputePass {
    enum Subtype {
        case naive
        case optimizedHorizontal
        case optimizedVertical
        case benchmark
    }
}
