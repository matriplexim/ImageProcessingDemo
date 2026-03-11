//
//  Renderer.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import Metal
import UIKit

final class Renderer {
    // MARK: Private properties
    private let context: GPUContext
    private let texturePool: TexturePool
    private let lutProvider: LUTProvider
    private let renderPipeline: RenderPipeline
    private let pipelineRegistry: ComputePipelineRegistry

    private var layer: CAMetalLayer?
    private var processingContinuation: CheckedContinuation<MTLTexture, Never>?

    // MARK: Initialization
    init(context: GPUContext) throws {
        self.context = context
        self.texturePool = TexturePool(context: context)
        self.lutProvider = LUTProvider(context: context)
        self.renderPipeline = RenderPipeline(
            context: context,
            pixelFormat: context.pixelFormat
        )
        self.pipelineRegistry = try ComputePipelineRegistry(
            context: context,
            texturePool: texturePool,
            lutProvider: lutProvider
        )
    }

    // MARK: Internal methods
    /// Binding Metal layer to renderer device and set up render settings
    /// - Parameter layer: Metal layer
    func bind(to layer: CAMetalLayer) {
        self.layer = layer
        layer.device = context.device
        layer.framebufferOnly = false
        layer.pixelFormat = .bgra8Unorm
    }

    /// Draw texture by Metal
    /// - Parameter texture: Texture to drawing
    func draw(texture: MTLTexture) {
        guard let drawable = layer?.nextDrawable(),
              let buffer = context.makeCommandBuffer(
                label: "Render Command Buffer"
              ) else {
            return
        }

        renderPipeline.encode(
            buffer: buffer,
            drawable: drawable,
            texture: texture
        )

        buffer.present(drawable)
        buffer.commit()
    }

    func makeProcessing(
        texture: MTLTexture,
        processingType: ProcessingType,
        isOptimized: Bool,
        completion: @escaping (MTLTexture?) -> Void
    ) {
        Task(priority: .high) {
            var textureSet = PipelineTextureSet(texturePool: texturePool)
            var outputTexture: MTLTexture?

            let buffer = context.makeCommandBuffer(
                label: "Compute Command Buffer",
                completionHandler: { buf in
                    let kernelEndTime = buf?.kernelEndTime ?? 0.0
                    let kernelStartTime = buf?.kernelStartTime ?? 0.0
                    print("### Kernel time: \(kernelEndTime - kernelStartTime)")
                    let gpuEndTime = buf?.gpuEndTime ?? 0.0
                    let gpuStartTime = buf?.gpuStartTime ?? 0.0
                    print("### GPU time: \(gpuEndTime - gpuStartTime)")
                    completion(outputTexture)
                }
            )
            if let buffer {
                // TODO: Problem with other LUT types: buffer range error
                lutProvider.prepareLUTTextureIfNeeded(commandBuffer: buffer, type: .minimal)
            }
            guard let encoder = buffer?.makeComputeCommandEncoder() else {
                completion(nil)
                return
            }

            let pipelineKey: ComputePipelineRegistry.PassKey = switch processingType {
            case .singleGrayscale:
                .grayscale
            case .singleSobel:
                .sobel
            case .multiPassSobel:
                .multiPassSobel(isOptimized: isOptimized)
            case .fullProcessing:
                .processing(isOptimized: isOptimized)
            }

            outputTexture = await pipelineRegistry.encode(
                encoder,
                key: pipelineKey,
                texture: texture,
                textureSet: &textureSet
            )

            encoder.endEncoding()
            buffer?.commit()
        }
    }

    func prepareResources(texture: MTLTexture) {
        Task(priority: .high) {
            await pipelineRegistry.prepareByTexture(texture)
        }
    }

    /// Make texture from `UIImage` to drawing
    /// - Parameter image: Image to drawing
    /// - Returns: Texture to render pipeline
    func makeTexture(image: UIImage) -> MTLTexture? {
        image.toMTLTexture(device: context.device)
    }
}
