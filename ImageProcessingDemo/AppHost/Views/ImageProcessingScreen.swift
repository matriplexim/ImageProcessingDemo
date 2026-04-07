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
                Text("Image size: \(viewModel.image?.size ?? "Undefined")")
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
                    Text("FPS: __:__:__")
                    Text("Latency: __:__:__")
                    Text("Tail latency: __:__:__")
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
                                        
                                        Text(image.id)
                                            .foregroundStyle(.background)
                                            .font(.title)
                                            .padding(10)
                                    }
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
}
