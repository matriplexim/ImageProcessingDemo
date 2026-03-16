//
//  PipelineTextureSet.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 24.01.2026.
//

import Metal

final class PipelineTextureSet {
    // MARK: Private properties
    private let context: GPUContext
    private let pool: TexturePool
    private var textures: [PipelineTextureOptions: [MTLTexture]] = [:]

    // MARK: Initialization
    init(
        context: GPUContext,
        texturePool: TexturePool
    ) {
        self.context = context
        self.pool = texturePool
    }

    // MARK: Internal properties
    func prewarm(requirements: [PipelineTextureRequirement]) async {
        for req in requirements {
            for _ in 0..<req.count {
                let texture = await pool.obtain(by: req.options)
                textures[req.options, default: []].append(texture)
            }
        }
    }

    func getTexture(options: PipelineTextureOptions) -> MTLTexture {
        if var existedTextures = textures[options],
           !existedTextures.isEmpty,
           let existedTexture = existedTextures.popLast() {
            return existedTexture
        } else {
            return context.makeTexture(
                width: options.width,
                height: options.height,
                pixelFormat: options.pixelFormat
            )!
        }
    }

    func releaseAll() {
        Task(priority: .medium) {
            await withTaskGroup(of: Void.self) { taskGroup in
                for texture in textures.values.joined() {
                    taskGroup.addTask {
                        await self.pool.release(texture)
                    }
                }

                await taskGroup.waitForAll()

                textures.removeAll()
            }
        }
    }
}
