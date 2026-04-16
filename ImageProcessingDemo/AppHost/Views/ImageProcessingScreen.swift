//
//  ImageProcessingScreen.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import SwiftUI

struct ImageProcessingScreen: View {
    @ObservedObject private var viewModel: ImageProcessingViewModel
    private let hostCoordinator: HostCoordinator

    init(viewModel: ImageProcessingViewModel, hostCoordinator: HostCoordinator) {
        self.viewModel = viewModel
        self.hostCoordinator = hostCoordinator
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Processing type: \(viewModel.processingType.id)")
                    .font(.headline)
                    .bold()
                Text("Compute type: \(viewModel.computeType.id)")
                    .font(.headline)
                    .bold()
                Text("Image size: \(viewModel.image?.sizeDescription ?? "Undefined")")
                    .font(.headline)
                    .bold()

                viewModel.image.map {
                    let maxHeight = (geometry.size.width / ($0.data?.size.width ?? 1.0)) * ($0.data?.size.height ?? 1.0)
                    return HostRenderingScreen(
                        hostCoordinator: hostCoordinator,
                        renderState: viewModel.renderState
                    ).frame(
                        maxWidth: geometry.size.width,
                        maxHeight: viewModel.appState.isDemo ? maxHeight : 0.0
                    )
                }
                .opacity(viewModel.appState.isDemo ? 1.0 : 0.0)

                VStack {
                    Text("USER METRICS")
                    metricsView(name: "Latency", value: viewModel.latency)
                    metricsView(name: "P95", value: viewModel.p95)
                    metricsView(name: "P99", value: viewModel.p99)
                    metricsView(name: "FPS", value: viewModel.fps)
                }
                .opacity(viewModel.appState.isDemo ? 0.0 : 1.0)

                Spacer()

                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            ForEach(viewModel.state.images) { image in
                                Button(action: {
                                    viewModel.image = image
                                }, label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 15)
                                        
                                        Text(image.name)
                                            .foregroundStyle(.background)
                                            .font(.title)
                                            .padding(10)
                                    }
                                    .opacity(viewModel.image?.id == image.id ? 1.0 : 0.5)
                                })
                                .padding(.leading, image.id == viewModel.state.images.first?.id ? 20 : 0)
                                .padding(.trailing, image.id == viewModel.state.images.last?.id ? 20 : 0)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    
                    HStack {
                        ForEach(viewModel.state.processingTypes) { type in
                            Button(action: {
                                viewModel.processingType = type
                            }, label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15.0)
                                        .frame(maxWidth: .infinity, maxHeight: 45)
                                    Text(type.id)
                                        .foregroundStyle(.background)
                                }
                                .opacity(viewModel.processingType == type ? 1.0 : 0.5)
                            })
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    HStack {
                        ForEach(ComputeType.allCases) { type in
                            Button(action: {
                                viewModel.computeType = type
                            }, label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15.0)
                                        .frame(maxWidth: .infinity, maxHeight: 45)
                                    Text(type.id)
                                        .foregroundStyle(.background)
                                }
                                .opacity(viewModel.computeType == type ? 1.0 : 0.5)
                            })
                        }
                    }
                    .padding(.horizontal, 20)

                    HStack {
                        ForEach(AppState.initialCases) { state in
                            Button(action: {
                                viewModel.appState = state
                            }, label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15.0)
                                        .frame(maxWidth: .infinity, maxHeight: 45)
                                    Text(state.id)
                                        .foregroundStyle(.background)
                                }
                                .opacity(viewModel.appState.id == state.id ? 1.0 : 0.5)
                            })
                        }
                    }
                    .padding(.horizontal, 20)

                    Toggle(isOn: $viewModel.isOptimized) {
                        Text("Is on optimized mode")
                    }
                    .padding(.horizontal, 20)

                    Button(action: {
                        viewModel.onTap()
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15.0)
                                .frame(maxWidth: .infinity, maxHeight: 45)
                            HStack {
                                if viewModel.appState.isProgress {
                                    ProgressView()
                                }

                                Text(viewModel.appState.buttonTitle)
                                    .foregroundStyle(.background)
                            }
                        }
                    })
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    @ViewBuilder private func metricsView(name: String, value: Double?) -> some View {
        if let value {
            Text("\(name): \(value)")
        } else {
            Text("\(name): N/A")
        }
    }
}
