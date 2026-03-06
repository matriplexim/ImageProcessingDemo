//
//  LUTProvider.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 14.02.2026.
//

import Metal

final class LUTProvider {
    // MARK: Private properties
    private let context: GPUContext
    private var texture: MTLTexture!
    private var lutBuffer: MTLBuffer!

    private var type: GPUContext.LUTType = .minimal
    private var state: State = .notReady

    // MARK: Initialization
    init(context: GPUContext) {
        self.context = context
    }

    // MARK: Internal properties
    func prepareLUTTextureIfNeeded(
        commandBuffer: MTLCommandBuffer,
        type: GPUContext.LUTType
    ) {
        if case .ready = state {
            return
        }

        state = .inProcess
        prepareData()

        if texture != nil,
           let lutBuffer {
            let encoder = commandBuffer.makeBlitCommandEncoder()
            encoder?.copy(
                from: lutBuffer,
                sourceOffset: 0,
                sourceBytesPerRow: type.bytesPerPixel * type.width,
                sourceBytesPerImage: 0,
                sourceSize: MTLSize(width: type.width, height: 1, depth: 1),
                to: texture,
                destinationSlice: 0,
                destinationLevel: 0,
                destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
            )
            encoder?.endEncoding()

            commandBuffer.addCompletedHandler { [weak self] _ in
                self?.state = .ready
            }
        }
    }

    func getLUTTexture() throws -> MTLTexture {
        guard case .notReady = state else {
            return texture
        }

        throw LUTProvider.Error.textureIsNotReady
    }
}

// MARK: - Private methods
extension LUTProvider {
    private func prepareData() {
        if texture == nil {
            texture = context.makeTexture(
                width: type.width,
                height: Constants.height2D,
                pixelFormat: type.pixelFormat,
                usage: .shaderRead
            )
        }

        if lutBuffer == nil {
            lutBuffer = context.makeLUTStagingBuffer(for: type)
        }
    }
}

// MARK: - State
extension LUTProvider {
    enum State {
        case notReady
        case inProcess
        case ready
    }
}

// MARK: - Error
extension LUTProvider {
    enum `Error`: Swift.Error {
        case textureIsNotReady
    }
}

// MARK: - Constants
private enum Constants {
    static let height2D: Int = 1
}
