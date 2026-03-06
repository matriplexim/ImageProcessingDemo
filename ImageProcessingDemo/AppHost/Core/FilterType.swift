//
//  FilterType.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 17.01.2026.
//

enum FilterType {
    case naiveSobel
    case optimizedSobel
    case naiveGauss
    case optimizedHorizontalGauss
    case optimizedVerticalGauss
    case heatmap
    case grayscale
    case singleGrayscale
    case singleSobel
    case tonemap
}

// MARK: - Internal properties
extension FilterType {
    /// Name of kernel function for each type
    var functionName: String {
        switch self {
        case .naiveSobel:
            "naiveSobelKernel"
        case .optimizedSobel:
            "optimizedSobelKernel"
        case .naiveGauss:
            "naive2DGaussKernel"
        case .optimizedHorizontalGauss:
            "optimizedHorizontalGauss"
        case .optimizedVerticalGauss:
            "optimizedVerticalGauss"
        case .heatmap:
            "heatmapKernel"
        case .grayscale:
            "grayscaleKernel"
        case .singleGrayscale:
            "singleGrayscaleKernel"
        case .singleSobel:
            "singleNaiveSobelKernel"
        case .tonemap:
            "tonemapKernel"
        }
    }

    var encoderLabel: String {
        switch self {
        case .naiveSobel:
            "Naive Sobel"
        case .optimizedSobel:
            "Optimized Sobel"
        case .naiveGauss:
            "Naive 2D Gaussian"
        case .optimizedHorizontalGauss:
            "Optimized Horizontal Gaussian"
        case .optimizedVerticalGauss:
            "Optimized Vertical Gaussian"
        case .heatmap:
            "Heatmap"
        case .grayscale:
            "Grayscale"
        case .singleGrayscale:
            "Single Grayscale"
        case .singleSobel:
            "Single Sobel"
        case .tonemap:
            "Tonemap"
        }
    }
}
