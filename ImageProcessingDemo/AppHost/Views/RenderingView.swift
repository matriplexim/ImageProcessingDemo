//
//  RenderingView.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import UIKit

final class RenderingView: UIView {
    // MARK: Internal properties
    /// Layer of Metal to draw by GPU
    let metalLayer: CAMetalLayer

    // MARK: Initialization
    init() {
        self.metalLayer = CAMetalLayer()
        super.init(frame: .zero)
        setupMetalLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Overrided methods
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutMetalLayer()
    }
}

// MARK: - Private methods
extension RenderingView {
    private func setupMetalLayer() {
        self.layer.addSublayer(metalLayer)
        layoutMetalLayer()
    }

    private func layoutMetalLayer() {
        let appScale = UIScreen.main.scale
        metalLayer.frame = bounds
        metalLayer.drawableSize = CGSize(
            width: bounds.width * appScale,
            height: bounds.height * appScale
        )
    }
}
