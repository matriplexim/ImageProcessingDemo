//
//  ImageProcessingViewModel.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import UIKit
import Combine

final class ImageProcessingViewModel: ObservableObject {
    @Published var renderState: RenderState?
    @Published var appState: AppState = .initialDemo
    @Published var image: UIImage? = UIImage(named: "image_128")

    private let renderer: Renderer
    private var cancellables: Set<AnyCancellable> = []

    init(renderer: Renderer) {
        self.renderer = renderer
        setupObserving()
    }

    func onTap() {
        guard let texture = renderState?.texture else {
            return
        }

        self.renderState = RenderState(
            texture: texture,
            frameID: "1"
        )
    }
}

extension ImageProcessingViewModel {
    private func setupObserving() {
        $image.sink(receiveValue: { [weak self] newImage in
            guard let newImage,
                  let texture = self?.renderer.makeTexture(image: newImage) else {
                return
            }

            self?.renderState = RenderState(
                texture: texture,
                frameID: UUID().uuidString
            )
        }).store(in: &cancellables)
    }
}
