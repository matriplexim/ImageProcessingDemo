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
                    isOptimized: computeSettings.isOptimized,
                    withMetrics: true,
                    withFinish: true
                )
                renderer.draw(texture: processedTexture)
            } catch { /* Error */ }
        case .processingBenchmark(let computeSettings):
            await benchmarkProcessing(
                texture: state.texture,
                computeSettings: computeSettings
            )
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

    private func benchmarkProcessing(
        texture: MTLTexture,
        computeSettings: RenderState.ComputeSettings
    ) async {
        var inputTexture = texture
        for _ in 0...50 {
            do {
                let resultTexture = try await renderer.makeProcessing(
                    texture: inputTexture,
                    processingType: computeSettings.type,
                    isOptimized: computeSettings.isOptimized,
                    withMetrics: false,
                    withFinish: false
                )
                inputTexture = resultTexture
            } catch {
                print("Benchmark processing failed: \(error)")
            }
        }

        let start = CACurrentMediaTime()
        print("### Start")
        for i in 0...1000 {
            do {
                let resultTexture = try await renderer.makeProcessing(
                    texture: inputTexture,
                    processingType: computeSettings.type,
                    isOptimized: computeSettings.isOptimized,
                    withMetrics: true,
                    withFinish: i == 1000 ? true : false
                )
                inputTexture = resultTexture
            } catch {
                print("Benchmark processing failed: \(error)")
            }
        }
        let end = CACurrentMediaTime()
        let gap = end - start
        let frameTime = gap / 1000
        let fps = 1.0 / frameTime

        print("### FPS: \(fps)")
    }
}
