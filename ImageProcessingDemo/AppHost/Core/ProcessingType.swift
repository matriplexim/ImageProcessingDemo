//
//  ProcessingType.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 17.01.2026.
//

enum ProcessingType: Identifiable {
    case singleGrayscale
    case singleSobel
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
        }
    }
}
