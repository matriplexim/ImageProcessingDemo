//
//  AppState.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

enum AppState: Identifiable {
    case initialDemo
    case progressDemo
    case resultDemo
    case initialBenchmark
    case progressBenchmark
    case resultBenchmark

    var id: String {
        switch self {
        case .initialDemo, .progressDemo, .resultDemo:
            "Demo"
        case .initialBenchmark, .progressBenchmark, .resultBenchmark:
            "Benchmark"
        }
    }
}

extension AppState {
    var isDemo: Bool {
        switch self {
        case .initialDemo, .progressDemo, .resultDemo:
            true
        default:
            false
        }
    }

    var isProgress: Bool {
        switch self {
        case .progressBenchmark, .progressDemo:
            true
        default:
            false
        }
    }

    var buttonTitle: String {
        switch self {
        case .initialBenchmark, .initialDemo:
            "Start processing"
        case .progressBenchmark, .progressDemo:
            "In progress..."
        case .resultBenchmark, .resultDemo:
            "Cancel"
        }
    }

    static var initialCases: [AppState] = [
        .initialDemo,
        .initialBenchmark
    ]
}
