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

    func prepareTextures(
        withRequirements requirements: [PipelineTextureRequirement]
    ) async {
        for req in requirements {
            await pool.prepareTextures(requirement: req)
        }
    }

    mutating func getTexture(options: PipelineTextureOptions) async -> MTLTexture {
        let texture = await pool.acquire(options: options)
        self.textures[options, default: []].append(texture)

        return texture
    }

    func makeTexture(options: PipelineTextureOptions) async -> MTLTexture {
        await pool.make(options: options)
    }

    func reset() async {
        for texture in textures.values.flatMap(\.self) {
            await pool.release(texture)
        }
    }
}
