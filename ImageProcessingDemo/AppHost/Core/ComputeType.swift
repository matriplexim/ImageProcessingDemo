//
//  ComputeType.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 07.04.2026.
//

enum ComputeType: Identifiable {
    case cpu
    case gpu

    var id: String {
        switch self {
        case .cpu:
            "CPU"
        case .gpu:
            "GPU"
        }
    }

    static let allCases: [ComputeType] = [
        .cpu,
        .gpu
    ]
}
