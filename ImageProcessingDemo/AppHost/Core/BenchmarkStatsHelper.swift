//
//  BenchmarkStatsHelper.swift
//  ImageProcessingDemo
//
//  Created by Максим Ломакин on 15.04.2026.
//

import Foundation

final class BenchmarkStatsHelper {
    func computeStats(latencies: [Double]) -> BenchmarkStats? {
        guard !latencies.isEmpty else {
            return nil
        }

        let sorted = latencies.sorted()
        let n = sorted.count

        // Median
        let median: Double = {
            if n % 2 == 0 {
                return (sorted[n/2 - 1] + sorted[n/2]) / 2.0
            } else {
                return sorted[n/2]
            }
        }()

        // Percentiles
        func percentile(_ p: Double) -> Double {
            let idx = min(n - 1, Int(Double(n) * p))
            return sorted[idx]
        }

        let p95 = percentile(0.95)
        let p99 = percentile(0.99)

        // FPS (через median — более стабильный)
        let fps = 1.0 / median

        return BenchmarkStats(
            median: median,
            p95: p95,
            p99: p99,
            fps: fps
        )
    }
}
