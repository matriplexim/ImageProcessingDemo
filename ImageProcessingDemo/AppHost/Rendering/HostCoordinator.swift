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

    private var link: CADisplayLink?
    private var renderState: RenderState?

    // MARK: Initialization
    init(renderer: Renderer) {
        self.renderer = renderer
    }

    // MARK: Internal methods
    /// Attach Metal layer to connect with GPU device and set up needed settings
    /// - Parameter layer: Layer of Metal to draw by GPU
    func attachLayer(_ layer: CAMetalLayer) {
        renderer.bind(to: layer)
        startRenderingLoop()
    }

    /// Update render state to draw new frame
    /// - Parameter state: Render state
    func updateRenderState(_ state: RenderState?) {
        renderState = state
    }
}

// MARK: - Private methods
extension HostCoordinator {
    private func startRenderingLoop() {
        link = CADisplayLink(target: self, selector: #selector(renderLoop(_ :)))
        link?.add(to: .main, forMode: .common)
    }

    @objc private func renderLoop(_ link: CADisplayLink) {
        guard let texture = renderState?.texture else {
            return
        }

        renderer.draw(texture: texture)
    }
}
