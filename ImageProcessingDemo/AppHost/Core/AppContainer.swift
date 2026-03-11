//
//  AppContainer.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import Metal
import SwiftUI

final class AppContainer {
    private let renderer: Renderer

    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary() else {
            return nil
        }

        let context = GPUContext(
            device: device,
            commandQueue: commandQueue,
            library: library,
            pixelFormat: .bgra8Unorm
        )
        guard let renderer = try? Renderer(context: context) else {
            return nil
        }

        self.renderer = renderer
    }

    func start() -> some View {
        ImageProcessingFeatureBuilder.build(renderer: renderer)
    }
}
