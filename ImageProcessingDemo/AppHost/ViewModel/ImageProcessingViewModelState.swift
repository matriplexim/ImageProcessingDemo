//
//  ImageProcessingViewModelState.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 07.04.2026.
//

import UIKit

@MainActor
final class ImageProcessingViewModelState: ObservableObject {
    let images: [ProcessingImage] = [
        ProcessingImage(
            id: "128 pixels",
            size: "128 × 128 pixels",
            data: UIImage(named: "cat_128")
        ),
        ProcessingImage(
            id: "SD",
            size: "259 × 194 pixels",
            data: UIImage(named: "cat_sd")
        ),
        ProcessingImage(
            id: "Full HD",
            size: "1920 × 1080 pixels",
            data: UIImage(named: "cat_full_hd")
        ),
        ProcessingImage(
            id: "2K",
            size: "2560 × 1440 pixels",
            data: UIImage(named: "cat_2K")
        ),
        ProcessingImage(
            id: "4K",
            size: "3840 × 2160 pixels",
            data: UIImage(named: "cat_4K")
        ),
        ProcessingImage(
            id: "High resolution",
            size: "5376 × 3072 pixels",
            data: UIImage(named: "cat_high_resolution")
        ),
    ]

    private(set) var processingTypes: [ProcessingType] = [
        ProcessingType.fullProcessing,
        ProcessingType.multiPassSobel,
        ProcessingType.singleGrayscale,
        ProcessingType.singleSobel
    ]

    func setupComputeType(_ computeType: ComputeType) {
        switch computeType {
        case .cpu:
            processingTypes.removeAll(where: { $0 == .multiPassSobel })
        case .gpu:
            processingTypes.append(.multiPassSobel)
        }
    }
}
