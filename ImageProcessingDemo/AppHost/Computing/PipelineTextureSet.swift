//
//  PipelineTextureSet.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 24.01.2026.
//

import Metal

struct PipelineTextureSet {
    private let pool: TexturePool
    private var textures: [PipelineTextureOptions: [MTLTexture]] = [:]

    init(texturePool: TexturePool) {
        self.pool = texturePool
    }

    func prepareTextures(withRequirements requirements: [PipelineTextureRequirement]) {
        for req in requirements {
            pool.prepareTextures(requirement: req)
        }
    }

    mutating func getTexture(options: PipelineTextureOptions) -> MTLTexture {
        let texture = pool.acquire(options: options)
        self.textures[options, default: []].append(texture)

        return texture
    }

    func makeTexture(options: PipelineTextureOptions) -> MTLTexture {
        pool.make(options: options)
    }

    func reset() {
        for texture in textures.values.flatMap(\.self) {
            pool.release(texture)
        }
    }
}
