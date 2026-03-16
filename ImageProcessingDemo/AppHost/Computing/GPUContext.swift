//
//  GPUContext.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 16.01.2026.
//

import Metal

final class GPUContext {
    // MARK: Private properties
    let device: MTLDevice
    let pixelFormat: MTLPixelFormat

    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary

    // MARK: Initialization
    init(
        device: MTLDevice,
        commandQueue: MTLCommandQueue,
        library: MTLLibrary,
        pixelFormat: MTLPixelFormat
    ) {
        self.device = device
        self.commandQueue = commandQueue
        self.library = library
        self.pixelFormat = pixelFormat
    }

    /// Make command buffer with label
    /// - Parameter label: Label of command buffer
    /// - Returns: Command buffer
    func makeCommandBuffer(label: String) throws -> MTLCommandBuffer {
        guard let buf = commandQueue.makeCommandBuffer() else {
            throw ProcessingError.emptyBuffer
        }

        buf.label = label
        return buf
    }

    func makeComputeEncoder(
        commandBuffer: MTLCommandBuffer
    ) throws -> MTLComputeCommandEncoder {
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw ProcessingError.emptyEncoder
        }

        return encoder
    }

    /// Make compute pipeline state by function name
    /// - Parameter functionName: Kernel function name
    /// - Returns: Compute pipeline state
    func makePipeline(functionName: String) -> MTLComputePipelineState? {
        guard let kernelFunction = library.makeFunction(name: functionName) else {
            return nil
        }

        return try? device.makeComputePipelineState(function: kernelFunction)
    }

    /// Make library function
    /// - Parameter name: Function name
    /// - Returns: Function
    func makeFunction(name: String) -> MTLFunction? {
        library.makeFunction(name: name)
    }

    /// Make 2D texture
    /// - Parameters:
    ///    - width: Texture width
    ///    - height: Texture height
    ///    - pixelFormat: Pixel format using in texture
    ///    - usage: Use type of texture
    /// - Returns: Texture
    func makeTexture(
        width: Int,
        height: Int,
        pixelFormat: MTLPixelFormat = .rgba8Unorm,
        usage: MTLTextureUsage = [.shaderRead, .shaderWrite]
    ) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )

        descriptor.usage = usage
        descriptor.storageMode = .private

        return device.makeTexture(descriptor: descriptor)
    }

    /// Make 2D LUT buffer
    /// - Parameter lutType: Type of LUT texture, contains texture settings
    /// - Returns: MTLBuffer containing LUT data.
    /// Need use `blit` encoder to pass LUT data from buffer to texture
    func makeLUTStagingBuffer(for type: LUTType) -> MTLBuffer? {
        switch type {
        case .minimal:
            return makeBuffer(type: type) { scalar in
                return [
                    UInt8(scalar * 255),
                    UInt8(abs(0.5 - scalar) * 255),
                    UInt8((1 - scalar) * 255),
                    255
                ]
            }

        case .full, .hdr:
            return makeBuffer(type: type) { scalar in
                return [
                    Float16(scalar),
                    Float16(abs(0.5 - scalar)),
                    Float16(1.0 - scalar),
                    Float16(1.0)
                ]
            }
        }
    }
}

// MARK: - Private methods
extension GPUContext {
    private func makeBuffer<T>(
        type: LUTType,
        generator: (Float) -> [T]
    ) -> MTLBuffer? {
        var data = [T]()
        data.reserveCapacity(type.width * 4)

        for i in 0..<type.width {
            let scalar = Float(i) / Float(type.width - 1)
            data.append(contentsOf: generator(scalar))
        }

        var buffer: MTLBuffer?
        let byteCount = data.count * MemoryLayout<T>.stride
        data.withUnsafeBufferPointer { pointer in
            guard let baseAddress = pointer.baseAddress else {
                return
            }

            buffer = device.makeBuffer(
                bytes: baseAddress,
                length: byteCount,
                options: [
                    .storageModeShared
                ]
            )
        }

        return buffer
    }
}

// MARK: - LUTType
extension GPUContext {
    enum LUTType {
        case minimal
        case full
        case hdr

        var width: Int {
            switch self {
            case .minimal:
                256
            case .full:
                512
            case .hdr:
                1024
            }
        }

        var pixelFormat: MTLPixelFormat {
            switch self {
            case .minimal:
                .rgba8Unorm
            case .full, .hdr:
                .rgba16Float
            }
        }

        var bytesPerPixel: Int {
            switch self {
            case .minimal:
                4
            case .full, .hdr:
                8
            }
        }
    }
}
