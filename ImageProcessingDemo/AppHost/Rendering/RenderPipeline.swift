//
//  RenderPipeline.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 14.02.2026.
//

import Metal
import QuartzCore

final class RenderPipeline {
    private let context: GPUContext
    private let pixelFormat: MTLPixelFormat
    private var pipeline: MTLRenderPipelineState?

    init(context: GPUContext, pixelFormat: MTLPixelFormat) {
        self.context = context
        self.pixelFormat = pixelFormat
        setupRenderPipeline()
    }

    func encode(
        buffer: MTLCommandBuffer,
        drawable: CAMetalDrawable,
        texture: MTLTexture
    ) {
        guard let pipeline else {
            setupRenderPipeline()
            return
        }

        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = drawable.texture
        passDescriptor.colorAttachments[0].storeAction = .store
        passDescriptor.colorAttachments[0].loadAction = .dontCare
        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 1.0,
            green: 1.0,
            blue: 1.0,
            alpha: 1.0
        )

        guard let encoder = buffer.makeRenderCommandEncoder(
            descriptor: passDescriptor
        ) else {
            return
        }

        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
    }
}

// MARK: - Private methods
extension RenderPipeline {
    private func setupRenderPipeline() {
        guard let vertexFunction = context.makeFunction(name: "fullScreenVertex"),
              let fragmentFunction = context.makeFunction(name: "fullScreenFragment") else {
            assertionFailure("Create shader functions failed")
            return
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "FullScreen"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat

        do {
            pipeline = try context
                .device
                .makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            assertionFailure("Create render pipeline failed: \(error)")
        }
    }
}
