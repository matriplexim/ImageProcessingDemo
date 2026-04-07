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

    private let renderer: Renderer
    private let computeProcessor: ComputeProcessor
    private var cancellables: Set<AnyCancellable> = []

    init(
        renderer: Renderer,
        computeProcessor: ComputeProcessor = ComputeProcessor()
    ) {
        self.renderer = renderer
        self.computeProcessor = computeProcessor
        image = state.images.first
        setupObserving()
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
        if appState.isDemo {
            appState = .progressDemo
        } else {
            appState = .progressBenchmark
        }

        switch computeType {
        case .cpu:
            computeByCPU()
        case .gpu:
            computeByGPU()
        }
    }

    private func computeByCPU() {
        guard let cgImage = image?.data?.cgImage else {
            return
        }

        Task.detached { [weak self] in
            guard let self else {
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
        self.image = ProcessingImage(
            id: self.image?.id ?? UUID().uuidString,
            size: "Processed \(self.image?.id ?? "N/A")",
            data: image
        )
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
}
