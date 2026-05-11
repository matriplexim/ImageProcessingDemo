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
    private let captureManager: MTLCaptureManager = .shared()
    private weak var delegate: RendererDelegate?

    @MainActor
    private var layer: CAMetalLayer?
    private var currentTextureOptions: Renderer.TextureOptions?

    private var counter: Int = 0

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

    func setDelegate(_ delegate: RendererDelegate) {
        self.delegate = delegate
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
        let frameStartTime = CACurrentMediaTime()
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
        buffer.addCompletedHandler { _ in
            let frameEndTime = CACurrentMediaTime()
            _ = frameEndTime - frameStartTime
        }
        buffer.commit()
    }

    func makeProcessing(
        texture: MTLTexture,
        processingType: ProcessingType,
        isOptimized: Bool,
        withMetrics: Bool,
        withFinish: Bool
    ) async throws -> MTLTexture {
        if withMetrics {
            counter += 1
        }

        if counter == 301 {
            makeCapture(commandQueue: context.commandQueue)
        }

        delegate?.didStartProcessing()
        let frameStartTime = CACurrentMediaTime()
        let buffer = try context.makeCommandBuffer(label: "Compute Buffer")

        lutProvider.prepareLUTTextureIfNeeded(commandBuffer: buffer, type: .minimal)

        let textureSet = await pipelineRegistry.prepareTextureSet(
            forTexture: texture,
            processingType: processingType
        )

        let resultTexture = try pipelineRegistry.encode(
            commandBuffer: buffer,
            texture: texture,
            textureSet: textureSet,
            processingType: processingType,
            isOptimized: isOptimized
        )

        var latency: Double?
        await withCheckedContinuation { continuation in
            buffer.addCompletedHandler { _ in
                let frameEndTime = CACurrentMediaTime()
                latency = frameEndTime - frameStartTime

                continuation.resume()
            }

            buffer.commit()
        }

        if counter == 500, captureManager.isCapturing {
            captureManager.stopCapture()
        }

        textureSet.releaseAll()

        if withMetrics, let latency {
            delegate?.didReceiveLatency(latency)
        }

        if withFinish {
            delegate?.didFinishProcessing()
        }

        return resultTexture
    }

    /// Make texture from `UIImage` to drawing
    /// - Parameter image: Image to drawing
    /// - Returns: Texture to render pipeline
    nonisolated func makeTexture(image: UIImage) -> MTLTexture? {
        image.toMTLTexture(device: context.device)
    }
}

// MARK: - Private methods
extension Renderer {
    private func makeCapture(commandQueue: MTLCommandQueue) {
        let descriptor = MTLCaptureDescriptor()
        descriptor.captureObject = commandQueue
        descriptor.destination = .developerTools

        do {
            try captureManager.startCapture(with: descriptor)
        } catch {
            print("Capture manager failed: \(error)")
        }
    }
}

// MARK: - TextureOptions
extension Renderer {
    struct TextureOptions: Hashable {
        let width: Int
        let height: Int
    }
}
