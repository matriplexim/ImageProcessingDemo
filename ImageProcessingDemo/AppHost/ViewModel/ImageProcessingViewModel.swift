//
//  ImageProcessingViewModel.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import UIKit
import Combine

@MainActor
final class ImageProcessingViewModel: ObservableObject {
    @Published var state = ImageProcessingViewModelState()
    @Published var renderState: RenderState?
    @Published var appState: AppState = .initialDemo
    @Published var image: ProcessingImage?
    @Published var processingType: ProcessingType = .fullProcessing
    @Published var computeType: ComputeType = .cpu
    @Published var isOptimized: Bool = false

    @Published var latency: Double? = nil
    @Published var p95: Double? = nil
    @Published var p99: Double? = nil
    @Published var fps: Double? = nil

    private var latencySum: Double = 0
    private var latencyMetrics: [Double] = []

    private let renderer: Renderer
    private let statsHelper: BenchmarkStatsHelper
    private let computeProcessor: ComputeProcessor
    private var cancellables: Set<AnyCancellable> = []

    init(
        renderer: Renderer,
        statsHelper: BenchmarkStatsHelper = BenchmarkStatsHelper(),
        computeProcessor: ComputeProcessor = ComputeProcessor()
    ) {
        self.renderer = renderer
        self.statsHelper = statsHelper
        self.computeProcessor = computeProcessor
        setupViewModel()
    }

    func onTap() {
        switch appState {
        case .initialBenchmark, .initialDemo:
            startProcessing()
        case .progressBenchmark, .progressDemo:
            break
        case .resultBenchmark, .resultDemo:
            guard let initialImage = state.images.first(
                where: { $0.id == image?.id }
            ) else {
                return
            }

            image = initialImage
            if appState.isDemo {
                appState = .initialDemo
            } else {
                appState = .initialBenchmark
            }
        }
    }
}

extension ImageProcessingViewModel {
    private func setupViewModel() {
        Task {
            image = state.images.first
            setupObserving()
            await renderer.setDelegate(self)
        }
    }

    private func setupObserving() {
        $image.sink(receiveValue: { [weak self] processingImage in
            guard let newImage = processingImage?.data,
                  let texture = self?.renderer.makeTexture(image: newImage) else {
                return
            }

            self?.renderState = RenderState(
                texture: texture,
                frameID: UUID().uuidString,
                mode: .initialDemo
            )
        })
        .store(in: &cancellables)

        $computeType.sink(receiveValue: { [weak self] type in
            self?.state.setupComputeType(type)
        })
        .store(in: &cancellables)
    }

    private func startProcessing() {
        switch computeType {
        case .cpu:
            computeByCPU()
        case .gpu:
            computeByGPU()
        }
    }

    private func computeByCPU() {
        progressAppState()
        guard let cgImage = image?.data?.cgImage else {
            finishAppState()
            return
        }

        Task.detached { [weak self] in
            guard let self else {
                await self?.finishAppState()
                return
            }

            let resultImage = await computeProcessor.processImage(
                cgImage,
                settings: RenderState.ComputeSettings(
                    type: await processingType,
                    isOptimized: await isOptimized
                )
            )
            await finishCPUProcessing(image: resultImage)
        }
    }

    private func finishCPUProcessing(image: UIImage) {
        let id = self.image?.id ?? UUID().uuidString
        let name = self.image?.name ?? "N/A"
        self.image = ProcessingImage(
            id: id,
            name: "Processed image: \(name)",
            size: image.size,
            data: image
        )
        finishAppState()
    }

    private func progressAppState() {
        if appState.isDemo {
            appState = .progressDemo
        } else {
            appState = .progressBenchmark
        }
    }

    private func finishAppState() {
        if appState.isDemo {
            appState = .resultDemo
        } else {
            appState = .resultBenchmark
        }
    }

    private func computeByGPU() {
        guard let texture = renderState?.texture else {
            return
        }

        let computeSettings = RenderState.ComputeSettings(
            type: processingType,
            isOptimized: isOptimized
        )
        let mode: RenderState.Mode = appState.isDemo ?
            .processingDemo(computeSettings) :
            .processingBenchmark(computeSettings)

        self.renderState = RenderState(
            texture: texture,
            frameID: UUID().uuidString,
            mode: mode
        )
    }

    private func computeMetrics() {
        let stats = statsHelper.computeStats(latencies: latencyMetrics)

        latency = stats?.median
        p95 = stats?.p95
        p99 = stats?.p99
        fps = stats?.fps

        latencyMetrics.removeAll(keepingCapacity: true)
    }
}

// MARK: - RendererDelegate
extension ImageProcessingViewModel: RendererDelegate {
    nonisolated func didStartProcessing() {
        Task {
            await progressAppState()
        }
    }

    nonisolated func didFinishProcessing() {
        Task {
            await computeMetrics()
            await finishAppState()
        }
    }

    nonisolated func didReceiveLatency(_ latency: Double) {
        Task { @MainActor in
            latencySum += latency * 1000
            latencyMetrics.append(latency)
        }
    }
}
