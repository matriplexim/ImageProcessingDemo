//
//  RendererDelegate.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 15.04.2026.
//

protocol RendererDelegate: AnyObject {
    /// Start of processing
    func didStartProcessing()

    /// Finish of processing with info
    func didFinishProcessing()

    func didReceiveLatency(_ latency: Double)
}
