//
//  HostRenderingScreen.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import SwiftUI

struct HostRenderingScreen {
    // MARK: Private properties
    private let hostCoordinator: HostCoordinator
    private var renderState: RenderState?

    // MARK: Initialization
    init(
        hostCoordinator: HostCoordinator,
        renderState: RenderState?
    ) {
        self.hostCoordinator = hostCoordinator
        self.renderState = renderState
    }
}

// MARK: - UIViewRepresentable
extension HostRenderingScreen: UIViewRepresentable {
    typealias UIViewType = RenderingView

    func makeCoordinator() -> HostCoordinator {
        hostCoordinator
    }

    func makeUIView(context: Context) -> RenderingView {
        let view = RenderingView()
        context.coordinator.attachLayer(view.metalLayer)

        return view
    }

    func updateUIView(_ uiView: RenderingView, context: Context) {
        context.coordinator.updateRenderState(renderState)
    }
}
