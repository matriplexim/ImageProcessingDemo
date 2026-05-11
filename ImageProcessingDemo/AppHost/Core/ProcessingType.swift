//
//  ProcessingType.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 17.01.2026.
//

enum ProcessingType: Identifiable {
    case singleGrayscale
    case singleSobel
    case gaussianBlur
    case multiPassSobel
    case fullProcessing

    var id: String {
        switch self {
        case .fullProcessing:
            "Full"
        case .multiPassSobel:
            "Multi Sobel"
        case .singleGrayscale:
            "Grayscale"
        case .singleSobel:
            "Sobel"
        case .gaussianBlur:
            "Gaussian Blur"
        }
    }

    var isOnlyGPU: Bool {
        switch self {
        case .gaussianBlur, .multiPassSobel:
            true
        case .fullProcessing, .singleGrayscale, .singleSobel:
            false
        }
    }
}
