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

        self.renderer = Renderer(
            context: GPUContext(
                device: device,
                commandQueue: commandQueue,
                library: library
            )
        )
    }

    func start() -> some View {
        ImageProcessingFeatureBuilder.build(renderer: renderer)
    }
}
