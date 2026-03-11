//
//  HostCoordinator.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import QuartzCore

final class HostCoordinator {
    // MARK: Private properties
    private let renderer: Renderer

    private var renderState: RenderState?
    private var hasRenderedFirstFrame = false

    // MARK: Initialization
    init(renderer: Renderer) {
        self.renderer = renderer
    }

    // MARK: Internal methods
    /// Attach Metal layer to connect with GPU device and set up needed settings
    /// - Parameter layer: Layer of Metal to draw by GPU
    func attachLayer(_ layer: CAMetalLayer) {
        renderer.bind(to: layer)
    }

    /// Update render state to draw new frame
    /// - Parameter state: Render state
    func updateRenderState(_ state: RenderState?) {
        guard let state else {
            return
        }

        // Check first frame rendering process
        guard hasRenderedFirstFrame else {
            renderState = state
            return
        }

        renderState = state
        switch state.mode {
        case .initialDemo:
            renderer.prepareResources(texture: state.texture)
            renderer.draw(texture: state.texture)
        case .processingDemo(let computeSettings):
            renderer.makeProcessing(
                texture: state.texture,
                processingType: computeSettings.type,
                isOptimized: computeSettings.isOptimized
            ) { [weak self] texture in
                guard let texture else {
                    return
                }

                self?.renderer.draw(texture: texture)
            }
        case .processingBenchmark(let computeSettings):
            break
        case .benchmark:
            break
        }
    }

    func renderFirstFrameIfNeeded() {
        guard !hasRenderedFirstFrame,
              let texture = renderState?.texture else {
            return
        }

        hasRenderedFirstFrame = true
        renderer.draw(texture: texture)
    }
}
