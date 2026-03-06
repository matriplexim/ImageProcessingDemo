//
//  ImageProcessingScreen.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import SwiftUI

struct ImageProcessingScreen: View {
    @ObservedObject private var viewModel: ImageProcessingViewModel
    private let hostCoordinator: HostCoordinator

    init(viewModel: ImageProcessingViewModel, hostCoordinator: HostCoordinator) {
        self.viewModel = viewModel
        self.hostCoordinator = hostCoordinator
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                viewModel.image.map {
                    HostRenderingScreen(
                        hostCoordinator: hostCoordinator,
                        renderState: viewModel.renderState
                    ).frame(
                        maxWidth: geometry.size.width,
                        maxHeight: (geometry.size.width / $0.size.width) * $0.size.height
                    )
                }
                Button("Tap to reload", action: {
                    viewModel.onTap()
                })
            }
        }
    }
}
