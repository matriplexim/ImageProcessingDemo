//
//  RenderState.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import Metal

struct RenderState {
    /// Drawing texture
    let texture: MTLTexture
    /// Frame identifier to change state context
    let frameID: String
    /// Mode of rendering
    let mode: RenderState.Mode

    init(
        texture: MTLTexture,
        frameID: String,
        mode: RenderState.Mode,
    ) {
        self.texture = texture
        self.frameID = frameID
        self.mode = mode
    }
}

// MARK: - Mode
extension RenderState {
    enum Mode {
        case initialDemo
        case processingDemo(ComputeSettings)
        case processingBenchmark(ComputeSettings)
        case benchmark
    }
}

// MARK: - ComputeSettings
extension RenderState {
    struct ComputeSettings {
        /// Type of compute processing
        let type: ProcessingType
        /// Flag is optimized compute processing
        let isOptimized: Bool
    }
}
