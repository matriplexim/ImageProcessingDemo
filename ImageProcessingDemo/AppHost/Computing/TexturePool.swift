//
//  TexturePool.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 24.01.2026.
//

import Metal

final actor TexturePool {
    private let context: GPUContext
    private var storage: [TexturePool.Key: [MTLTexture]] = [:]

    init(context: GPUContext) {
        self.context = context
    }

    func prepareTextures(requirements: [PipelineTextureRequirement]) {
        for req in requirements {
            prepareTextures(requirement: req)
        }
    }

    func prepareTextures(requirement: PipelineTextureRequirement) {
        let key = TexturePool.Key(
            width: requirement.options.width,
            height: requirement.options.height,
            pixelFormat: requirement.options.pixelFormat
        )

        let existingCount = storage[key]?.count ?? 0
        let diff = max(0, requirement.count - existingCount)

        for _ in 0..<diff {
            guard let texture = context.makeTexture(
                width: requirement.options.width,
                height: requirement.options.height,
                pixelFormat: requirement.options.pixelFormat
            ) else {
                continue
            }

            storage[key, default: []].append(texture)
        }
    }

    func acquire(options: PipelineTextureOptions) -> MTLTexture {
        let key = TexturePool.Key(
            width: options.width,
            height: options.height,
            pixelFormat: options.pixelFormat
        )

        if var arr = storage[key], !arr.isEmpty {
            let texture = arr.removeLast()
            storage[key] = arr

            return texture
        } else {
            return make(options: options)
        }
    }

    func make(options: PipelineTextureOptions) -> MTLTexture {
        let texture = context.makeTexture(
            width: options.width,
            height: options.height,
            pixelFormat: options.pixelFormat
        )!

        return texture
    }

    func release(_ texture: MTLTexture) {
        let key = Key(
            width: texture.width,
            height: texture.height,
            pixelFormat: texture.pixelFormat
        )

        storage[key, default: []].append(texture)
    }
}

// MARK: - Key
extension TexturePool {
    struct Key: Hashable {
        let width: Int
        let height: Int
        let pixelFormat: MTLPixelFormat
    }
}
