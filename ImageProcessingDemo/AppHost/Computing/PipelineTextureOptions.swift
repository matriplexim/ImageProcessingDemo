//
//  PipelineTextureOptions.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 24.01.2026.
//

import Metal

struct PipelineTextureOptions: Hashable {
    let width: Int
    let height: Int
    let pixelFormat: MTLPixelFormat
}
