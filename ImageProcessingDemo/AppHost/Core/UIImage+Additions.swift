//
//  UIImage+Additions.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import MetalKit

extension UIImage {
    /// Convert to MTLTexture
    /// - Parameters:
    ///    - device: GPU device
    ///    - usage: Texture usage settings
    /// - Returns: MTLTexture
    func toMTLTexture(device: MTLDevice, usage: MTLTextureUsage = [.shaderRead]) -> MTLTexture? {
        guard let cgImage else {
            return nil
        }

        let loader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option: Any] = [
            .SRGB: false,
            .textureStorageMode: MTLStorageMode.private.rawValue,
            .textureUsage: usage.rawValue
        ]

        return try? loader.newTexture(
            cgImage: cgImage,
            options: options
        )
    }
}
