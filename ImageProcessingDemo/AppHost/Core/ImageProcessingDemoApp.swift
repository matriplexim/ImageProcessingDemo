//
//  ImageProcessingDemoApp.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 13.01.2026.
//

import SwiftUI

@main
struct ImageProcessingDemoApp: App {
    private let appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            appContainer?.start()
        }
    }
}
