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
    /// Compute settings
    let computeSettings: RenderState.ComputeSettings?

    init(
        texture: MTLTexture,
        frameID: String,
        mode: RenderState.Mode,
        computeSettings: RenderState.ComputeSettings? = nil
    ) {
        self.texture = texture
        self.frameID = frameID
        self.mode = mode
        self.computeSettings = computeSettings
    }
}

// MARK: - Mode
extension RenderState {
    enum Mode {
        case demo
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
