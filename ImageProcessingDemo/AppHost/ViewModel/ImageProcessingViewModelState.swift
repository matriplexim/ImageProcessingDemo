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
            id: "low",
            name: "Low size image",
            size: CGSize(width: 1000, height: 667),
            data: UIImage(named: "cat_low")
        ),
        ProcessingImage(
            id: "medium",
            name: "Medium size image",
            size: CGSize(width: 1500, height: 1000),
            data: UIImage(named: "cat_medium")
        ),
        ProcessingImage(
            id: "large",
            name: "Large size image",
            size: CGSize(width: 2000, height: 1333),
            data: UIImage(named: "cat_large")
        ),
        ProcessingImage(
            id: "high",
            name: "High quality image",
            size: CGSize(width: 5824, height: 3264),
            data: UIImage(named: "cat_high")
        )
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
