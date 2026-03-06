//
//  ImageProcessingFeatureBuilder.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

enum ImageProcessingFeatureBuilder {
    static func build(renderer: Renderer) -> ImageProcessingScreen {
        let hostCoordinator = HostCoordinator(renderer: renderer)
        let viewModel = ImageProcessingViewModel(renderer: renderer)
        let screen = ImageProcessingScreen(
            viewModel: viewModel,
            hostCoordinator: hostCoordinator
        )

        return screen
    }
}
