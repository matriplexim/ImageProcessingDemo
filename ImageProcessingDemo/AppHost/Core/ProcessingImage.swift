//
//  ProcessingImage.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 07.04.2026.
//

import UIKit

struct ProcessingImage: Identifiable {
    let id: String
    let name: String
    let size: CGSize
    let data: UIImage?

    var sizeDescription: String {
        "\(size.width) x \(size.height) pixels"
    }
}
