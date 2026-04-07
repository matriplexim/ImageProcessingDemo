//
//  HostCoordinator.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import QuartzCore

@MainActor final class HostCoordinator {
    // MARK: Private properties
    private let renderer: Renderer

    private var renderState: RenderState?
    private var nextRenderState: RenderState?

    private var isLayerAttached = false
    private var isRendering = false

    // MARK: Initialization
    init(renderer: Renderer) {
        self.renderer = renderer
    }

    // MARK: Internal methods
    /// Attach Metal layer to connect with GPU device and set up needed settings
    /// - Parameter layer: Layer of Metal to draw by GPU
    func attachLayer(_ layer: CAMetalLayer) {
        guard !isLayerAttached else {
            return
        }

        isLayerAttached = true
        renderer.bind(to: layer)
    }

    /// Update render state to draw new frame
    /// - Parameter state: Render state
    func updateRenderState(_ state: RenderState?) {
        guard let state,
              renderState?.frameID != state.frameID else {
            return
        }

        if isRendering {
            nextRenderState = state
            return
        }

        renderState = state
        isRendering = true
        Task {
            await runRenderPipeline(withState: state)
        }
    }
}

// MARK: - Private methods
extension HostCoordinator {
    private func drawFrame(withTexture texture: MTLTexture) async {
        await renderer.prewarm(texture: texture)
        renderer.draw(texture: texture)
    }

    private func runRenderPipeline(withState state: RenderState) async {
        defer {
            completeRenderPipeline()
        }

        switch state.mode {
        case .initialDemo:
            await drawFrame(withTexture: state.texture)
        case .processingDemo(let computeSettings):
            do {
                let processedTexture = try await renderer.makeProcessing(
                    texture: state.texture,
                    processingType: computeSettings.type,
                    isOptimized: computeSettings.isOptimized
                )
                renderer.draw(texture: processedTexture)
            } catch { /* Error */ }
        default:
            break
        }
    }

    private func completeRenderPipeline() {
        isRendering = false
        guard let nextRenderState else {
            return
        }

        self.nextRenderState = nil
        updateRenderState(nextRenderState)
    }
}
