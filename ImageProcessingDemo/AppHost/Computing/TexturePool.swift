//
//  TexturePool.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 24.01.2026.
//

import Metal

final actor TexturePool {
    // MARK: Private properties
    private let context: GPUContext
    private var storage: [TexturePool.Key: [MTLTexture]] = [:]

    // MARK: Initialization
    init(context: GPUContext) {
        self.context = context
    }

    // MARK: Internal methods
    func prewarm(requirements: [PipelineTextureRequirement]) {
        for req in requirements {
            prewarm(requirement: req)
        }
    }

    func obtain(by options: PipelineTextureOptions) -> MTLTexture {
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
            return makeTexture(options: options)!
        }
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

// MARK: - Private methods
extension TexturePool {
    private func makeTexture(options: PipelineTextureOptions) -> MTLTexture? {
        context.makeTexture(
            width: options.width,
            height: options.height,
            pixelFormat: options.pixelFormat
        )
    }

    private func prewarm(requirement: PipelineTextureRequirement) {
        let key = TexturePool.Key(
            width: requirement.options.width,
            height: requirement.options.height,
            pixelFormat: requirement.options.pixelFormat
        )

        let existingCount = storage[key]?.count ?? 0
        let needed = max(0, requirement.count - existingCount)

        for _ in 0..<needed {
            if let texture = makeTexture(options: requirement.options) {
                storage[key, default: []].append(texture)
            }
        }
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
