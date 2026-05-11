//
//  ComputeProcessor.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 28.03.2026.
//

import Accelerate
import UIKit
import CoreGraphics

final class ComputeProcessor {
    func processImageBenchmark(
        _ cgImage: CGImage,
        settings: RenderState.ComputeSettings,
        completionLatency: @escaping (Double) -> Void
    ) -> UIImage {
        let allStartTime = CACurrentMediaTime()
        var inputImage = cgImage

        for _ in 1...25 {
            let startTime = CACurrentMediaTime()
            let result = processImage(inputImage, settings: settings)
            let endTime = CACurrentMediaTime()
            completionLatency(endTime - startTime)
            inputImage = result.cgImage ?? cgImage
        }

        let allFinalTime = CACurrentMediaTime()
        let allLatency = allFinalTime - allStartTime
        print("All latency: \(allLatency)")
        return UIImage(cgImage: inputImage)
    }

    func processImage(
        _ cgImage: CGImage,
        settings: RenderState.ComputeSettings
    ) -> UIImage {
        var resultImage: UIImage?

        switch settings.type {
        case .singleGrayscale:
            if settings.isOptimized {
                resultImage = processGrayscaleVImage(cgImage)
            } else {
                resultImage = processGrayscale(cgImage, isOptimized: false)
            }
        case .singleSobel:
            if settings.isOptimized {
                resultImage = processSobelVImage(cgImage)
            } else {
                resultImage = processSobel(cgImage)
            }
        case .multiPassSobel, .gaussianBlur:
            break
        case .fullProcessing:
            resultImage = processFullProcessingVImage(cgImage)
        }

        return resultImage ?? UIImage(cgImage: cgImage)
    }
}

// MARK: - Private methods
extension ComputeProcessor {
    private func processGrayscale(
        _ cgImage: CGImage,
        isOptimized: Bool
    ) -> UIImage? {
        let width = cgImage.width
        let height = cgImage.height

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        if isOptimized {
            DispatchQueue.concurrentPerform(iterations: width * height) { i in
                let idx = i * 4

                let r = Float(pixelData[idx])
                let g = Float(pixelData[idx + 1])
                let b = Float(pixelData[idx + 2])

                let gray = UInt8(0.299 * r + 0.587 * g + 0.114 * b)

                pixelData[idx]     = gray
                pixelData[idx + 1] = gray
                pixelData[idx + 2] = gray
            }
        } else {
            for i in stride(from: 0, to: pixelData.count, by: 4) {
                let r = Float(pixelData[i])
                let g = Float(pixelData[i + 1])
                let b = Float(pixelData[i + 2])
                
                let gray = UInt8(0.299 * r + 0.587 * g + 0.114 * b)
                
                pixelData[i]     = gray
                pixelData[i + 1] = gray
                pixelData[i + 2] = gray
            }
        }

        guard let outputCGImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: outputCGImage)
    }

    func processGrayscaleVImage(_ cgImage: CGImage) -> UIImage? {
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: Unmanaged.passUnretained(CGColorSpaceCreateDeviceRGB()),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )

        var sourceBuffer = vImage_Buffer()
        var error = vImageBuffer_InitWithCGImage(
            &sourceBuffer,
            &format,
            nil,
            cgImage,
            vImage_Flags(kvImageNoFlags)
        )
        guard error == kvImageNoError else {
            return nil
        }
        defer {
            free(sourceBuffer.data)
        }

        var destBuffer = vImage_Buffer()
        error = vImageBuffer_Init(
            &destBuffer,
            sourceBuffer.height,
            sourceBuffer.width,
            8,
            vImage_Flags(kvImageNoFlags)
        )
        guard error == kvImageNoError else {
            return nil
        }
        defer {
            free(destBuffer.data)
        }

        let divisor: Int32 = 256
        let coefficients: [Int16] = [
            Int16(0.299 * Float(divisor)),
            Int16(0.587 * Float(divisor)),
            Int16(0.114 * Float(divisor)),
            0
        ]

        error = vImageMatrixMultiply_ARGB8888ToPlanar8(
            &sourceBuffer,
            &destBuffer,
            coefficients,
            divisor,
            nil,
            0,
            vImage_Flags(kvImageNoFlags)
        )

        guard error == kvImageNoError else { return nil }

        var grayFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            colorSpace: Unmanaged.passUnretained(CGColorSpaceCreateDeviceGray()),
            bitmapInfo: CGBitmapInfo(),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )

        guard let cgImageResult = vImageCreateCGImageFromBuffer(
            &destBuffer,
            &grayFormat,
            nil,
            nil,
            vImage_Flags(kvImageNoFlags),
            &error
        )?.takeRetainedValue() else {
            return nil
        }

        return UIImage(cgImage: cgImageResult)
    }

    private func processSobel(_ cgImage: CGImage) -> UIImage? {
        let width = cgImage.width
        let height = cgImage.height

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        var input = [UInt8](repeating: 0, count: width * height * 4)
        var output = [UInt8](repeating: 0, count: width * height * 4)

        guard let context = CGContext(
            data: &input,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        func gray(_ idx: Int) -> Float {
            let r = Float(input[idx])
            let g = Float(input[idx + 1])
            let b = Float(input[idx + 2])
            return 0.299 * r + 0.587 * g + 0.114 * b
        }

        let w = width

        for y in 1..<height-1 {
            for x in 1..<width-1 {

                let i = (y * w + x) * 4

                // соседние пиксели
                let tl = gray(((y-1) * w + (x-1)) * 4)
                let tc = gray(((y-1) * w + x) * 4)
                let tr = gray(((y-1) * w + (x+1)) * 4)

                let ml = gray((y * w + (x-1)) * 4)
                let mr = gray((y * w + (x+1)) * 4)

                let bl = gray(((y+1) * w + (x-1)) * 4)
                let bc = gray(((y+1) * w + x) * 4)
                let br = gray(((y+1) * w + (x+1)) * 4)

                // Sobel kernels
                let gx = (-1*tl + 0 + 1*tr)
                       + (-2*ml + 0 + 2*mr)
                       + (-1*bl + 0 + 1*br)

                let gy = (-1*tl - 2*tc - 1*tr)
                       + (0 + 0 + 0)
                       + (1*bl + 2*bc + 1*br)

                let magnitude = sqrt(gx*gx + gy*gy)

                let value = UInt8(min(255, max(0, magnitude)))

                output[i] = value
                output[i + 1] = value
                output[i + 2] = value
                output[i + 3] = input[i + 3]
            }
        }

        guard let outContext = CGContext(
            data: &output,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ),
        let cgOut = outContext.makeImage() else {
            return nil
        }

        return UIImage(cgImage: cgOut)
    }

    func processSobelVImage(_ cgImage: CGImage) -> UIImage? {
        // MARK: - Source
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: Unmanaged.passUnretained(CGColorSpaceCreateDeviceRGB()),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )

        var src = vImage_Buffer()
        guard vImageBuffer_InitWithCGImage(&src, &format, nil, cgImage, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }

        defer {
            free(src.data)
        }

        // MARK: - Grayscale (IMPORTANT: use temp buffer correctly)
        var gray = vImage_Buffer()
        guard vImageBuffer_Init(&gray, src.height, src.width, 8, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }

        defer {
            free(gray.data)
        }

        let coeffs: [Int16] = [77, 150, 29, 0]

        guard vImageMatrixMultiply_ARGB8888ToPlanar8(
            &src,
            &gray,
            coeffs,
            256,
            nil,
            0,
            vImage_Flags(kvImageNoFlags)
        ) == kvImageNoError else {
            return nil
        }

        // MARK: - Output buffers
        var gx = vImage_Buffer()
        var gy = vImage_Buffer()

        guard vImageBuffer_Init(&gx, gray.height, gray.width, 8, vImage_Flags(kvImageNoFlags)) == kvImageNoError,
              vImageBuffer_Init(&gy, gray.height, gray.width, 8, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }

        defer {
            free(gx.data)
            free(gy.data)
        }

        let kx: [Int16] = [
            -1, 0, 1,
            -2, 0, 2,
            -1, 0, 1
        ]

        let ky: [Int16] = [
            -1, -2, -1,
             0,  0,  0,
             1,  2,  1
        ]

        // MARK: - Convolution X
        guard vImageConvolve_Planar8(
            &gray,
            &gx,
            nil,
            0,
            0,
            kx,
            3,
            3,
            1,
            0,
            vImage_Flags(kvImageEdgeExtend)
        ) == kvImageNoError else {
            return nil
        }

        // MARK: - Convolution Y
        guard vImageConvolve_Planar8(
            &gray,
            &gy,
            nil,
            0,
            0,
            ky,
            3,
            3,
            1,
            0,
            vImage_Flags(kvImageEdgeExtend)
        ) == kvImageNoError else {
            return nil
        }

        // MARK: - Output
        var out = vImage_Buffer()
        guard vImageBuffer_Init(&out, gray.height, gray.width, 8, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }

        defer {
            free(out.data)
        }

        // SAFE magnitude (no vImageHypotenuse)
        let gxPtr = gx.data!.assumingMemoryBound(to: UInt8.self)
        let gyPtr = gy.data!.assumingMemoryBound(to: UInt8.self)
        let outPtr = out.data!.assumingMemoryBound(to: UInt8.self)

        let count = Int(gray.height * gray.width)

        for i in 0..<count {
            let x = Float(gxPtr[i])
            let y = Float(gyPtr[i])

            let mag = sqrt(x * x + y * y)
            outPtr[i] = UInt8(min(mag, 255))
        }

        // MARK: - Result
        var outFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            colorSpace: Unmanaged.passUnretained(CGColorSpaceCreateDeviceGray()),
            bitmapInfo: CGBitmapInfo(),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )

        var error: vImage_Error = kvImageNoError

        guard let cg = vImageCreateCGImageFromBuffer(
            &out,
            &outFormat,
            nil,
            nil,
            vImage_Flags(kvImageNoFlags),
            &error
        )?.takeRetainedValue() else {
            return nil
        }

        return UIImage(cgImage: cg)
    }

    // MARK: Full Processing
    private func processFullProcessingVImage(_ cgImage: CGImage) -> UIImage? {
        guard var gray = try? makeGrayscaleBuffer(from: cgImage) else {
            return nil
        }

        defer { free(gray.data) }

        guard var blurred = makeBlurredBuffer(from: &gray) else {
            return nil
        }

        defer { free(blurred.data) }

        guard var edges = makeSobelMagnitude(from: &blurred) else {
            return nil
        }

        defer { free(edges.data) }

        normalize(&edges)

        return makeHeatmap(from: edges)
    }

    private func makeGrayscaleBuffer(from cgImage: CGImage) throws -> vImage_Buffer {
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: Unmanaged.passUnretained(CGColorSpaceCreateDeviceRGB()),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )

        var src = vImage_Buffer()
        var err = vImageBuffer_InitWithCGImage(&src, &format, nil, cgImage, vImage_Flags(kvImageNoFlags))
        guard err == kvImageNoError else { throw URLError(.cannotDecodeContentData) }

        defer { free(src.data) }

        var dst = vImage_Buffer()
        err = vImageBuffer_Init(&dst, src.height, src.width, 8, vImage_Flags(kvImageNoFlags))
        guard err == kvImageNoError else { throw URLError(.cannotCreateFile) }

        let divisor: Int32 = 256
        let coeffs: [Int16] = [
            Int16(0.299 * Float(divisor)),
            Int16(0.587 * Float(divisor)),
            Int16(0.114 * Float(divisor)),
            0
        ]

        err = vImageMatrixMultiply_ARGB8888ToPlanar8(
            &src,
            &dst,
            coeffs,
            divisor,
            nil,
            0,
            vImage_Flags(kvImageNoFlags)
        )

        guard err == kvImageNoError else {
            free(dst.data)
            throw URLError(.cannotDecodeContentData)
        }

        return dst
    }

    private func makeBlurredBuffer(from src: inout vImage_Buffer) -> vImage_Buffer? {
        var dst = vImage_Buffer()
        var err = vImageBuffer_Init(&dst, src.height, src.width, 8, vImage_Flags(kvImageNoFlags))
        guard err == kvImageNoError else { return nil }

        var temp = vImage_Buffer()
        err = vImageBuffer_Init(&temp, src.height, src.width, 8, vImage_Flags(kvImageNoFlags))
        guard err == kvImageNoError else {
            free(dst.data)
            return nil
        }

        defer { free(temp.data) }

        err = vImageBoxConvolve_Planar8(
            &src,
            &dst,
            &temp,
            0,
            0,
            5,
            5,
            0,
            vImage_Flags(kvImageEdgeExtend)
        )

        guard err == kvImageNoError else {
            free(dst.data)
            return nil
        }

        return dst
    }

    private func makeSobelMagnitude(from src: inout vImage_Buffer) -> vImage_Buffer? {
        var gx = vImage_Buffer()
        var gy = vImage_Buffer()

        guard vImageBuffer_Init(&gx, src.height, src.width, 8, vImage_Flags(kvImageNoFlags)) == kvImageNoError,
              vImageBuffer_Init(&gy, src.height, src.width, 8, vImage_Flags(kvImageNoFlags)) == kvImageNoError
        else { return nil }

        defer {
            free(gx.data)
            free(gy.data)
        }

        let kernelX: [Int16] = [
            -1, 0, 1,
            -2, 0, 2,
            -1, 0, 1
        ]

        let kernelY: [Int16] = [
             1,  2,  1,
             0,  0,  0,
            -1, -2, -1
        ]

        _ = kernelX.withUnsafeBufferPointer { kx in
            vImageConvolve_Planar8(
                &src,
                &gx,
                nil,
                0,
                0,
                kx.baseAddress!,
                3,
                3,
                1,
                128,
                vImage_Flags(kvImageEdgeExtend)
            )
        }

        _ = kernelY.withUnsafeBufferPointer { ky in
            vImageConvolve_Planar8(
                &src,
                &gy,
                nil,
                0,
                0,
                ky.baseAddress!,
                3,
                3,
                1,
                128,
                vImage_Flags(kvImageEdgeExtend)
            )
        }

        // magnitude
        var dst = vImage_Buffer()
        guard vImageBuffer_Init(&dst, src.height, src.width, 8, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }

        let px = gx.data!.assumingMemoryBound(to: UInt8.self)
        let py = gy.data!.assumingMemoryBound(to: UInt8.self)
        let pd = dst.data!.assumingMemoryBound(to: UInt8.self)

        let count = Int(src.width * src.height)

        for i in 0..<count {
            let fx = Float(Int(px[i]) - 128)
            let fy = Float(Int(py[i]) - 128)
            let mag = sqrt(fx * fx + fy * fy)
            pd[i] = UInt8(min(255, mag))
        }

        return dst
    }

    private func normalize(_ buffer: inout vImage_Buffer) {
        let ptr = buffer.data!.assumingMemoryBound(to: UInt8.self)
        let count = Int(buffer.width * buffer.height)

        var maxVal: UInt8 = 0
        for i in 0..<count {
            maxVal = max(maxVal, ptr[i])
        }

        guard maxVal > 0 else { return }

        let scale = 255.0 / Float(maxVal)

        for i in 0..<count {
            ptr[i] = UInt8(Float(ptr[i]) * scale)
        }
    }

    private func makeHeatmap(from buffer: vImage_Buffer) -> UIImage? {
        let width = Int(buffer.width)
        let height = Int(buffer.height)

        let src = buffer.data!.assumingMemoryBound(to: UInt8.self)

        var rgba = [UInt8](repeating: 0, count: width * height * 4)

        for i in 0..<(width * height) {
            let v = src[i]
            let c = heatColor(v)

            rgba[i*4+0] = c.r
            rgba[i*4+1] = c.g
            rgba[i*4+2] = c.b
            rgba[i*4+3] = 255
        }

        guard let ctx = CGContext(
            data: &rgba,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ),
        let cg = ctx.makeImage()
        else { return nil }

        return UIImage(cgImage: cg)
    }

    private func heatColor(_ v: UInt8) -> (r: UInt8, g: UInt8, b: UInt8) {
        let scalar = Float(v) / 255.0

        let r = UInt8(scalar * 255.0)
        let g = UInt8(abs(0.5 - scalar) * 255.0)
        let b = UInt8((1.0 - scalar) * 255.0)

        return (r, g, b)
    }
}
