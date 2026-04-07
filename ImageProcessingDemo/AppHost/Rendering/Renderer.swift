//
//  Renderer.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import Metal
import UIKit

final actor Renderer {
    // MARK: Private properties
    private nonisolated let context: GPUContext
    private let texturePool: TexturePool
    private let lutProvider: LUTProvider
    private nonisolated let renderPipeline: RenderPipeline
    private let pipelineRegistry: ComputePipelineRegistry

    @MainActor
    private var layer: CAMetalLayer?
    private var currentTextureOptions: Renderer.TextureOptions?

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
    @MainActor func bind(to layer: CAMetalLayer) {
        self.layer = layer
        layer.device = context.device
        layer.framebufferOnly = true
        layer.pixelFormat = context.pixelFormat
    }

    func prewarm(texture: MTLTexture) async {
        let textureOptions = Renderer.TextureOptions(
            width: texture.width,
            height: texture.height
        )
        guard currentTextureOptions != textureOptions else {
            return
        }

        currentTextureOptions = textureOptions
        await pipelineRegistry.prewarm(texture)
    }

    /// Draw texture by Metal
    /// - Parameter texture: Texture to drawing
    @MainActor func draw(texture: MTLTexture) {
        guard let drawable = layer?.nextDrawable(),
              let buffer = try? context.makeCommandBuffer(label: "Render Buffer") else {
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
        isOptimized: Bool
    ) async throws -> MTLTexture {
        let buffer = try context.makeCommandBuffer(label: "Compute Buffer")

        lutProvider.prepareLUTTextureIfNeeded(commandBuffer: buffer, type: .minimal)

        let textureSet = await pipelineRegistry.prepareTextureSet(
            forTexture: texture,
            processingType: processingType
        )

        let resultTexture = try pipelineRegistry.encode(
            commandBuffer: buffer,
            texture: texture,
            processingType: processingType,
            isOptimized: isOptimized
        )

        await withCheckedContinuation { continuation in
            buffer.addCompletedHandler { completedBuffer in
                print("GPU Latency: \(completedBuffer.gpuEndTime - completedBuffer.gpuStartTime)")
                continuation.resume()
            }

            buffer.commit()
        }

        textureSet.releaseAll()
        return resultTexture
    }

    /// Make texture from `UIImage` to drawing
    /// - Parameter image: Image to drawing
    /// - Returns: Texture to render pipeline
    nonisolated func makeTexture(image: UIImage) -> MTLTexture? {
        image.toMTLTexture(device: context.device)
    }
}

// MARK: - TextureOptions
extension Renderer {
    struct TextureOptions: Hashable {
        let width: Int
        let height: Int
    }
}
