//
//  AppMetrics.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/27/25.
//

import Metrics
import Prometheus

enum PackageAddSource: String {
    case email,
         api
}

struct AppMetrics {
    var metricsFactory: PrometheusMetricsFactory

    static let shared: AppMetrics = .init()

    init() {
        metricsFactory = PrometheusMetricsFactory(
            registry: PrometheusCollectorRegistry()
        )

        metricsFactory.valueHistogramBuckets["inbox_size"] = [
            0, 1, 2, 3, 5, 8, 13, 15,
        ]
    }

    func packagesCounter(source: PackageAddSource) -> any CounterHandler {
        metricsFactory.makeCounter(
            label: "packages",
            dimensions: [("source", source.rawValue)]
        )
    }

    func notificationCounter() -> any CounterHandler {
        metricsFactory.makeCounter(
            label: "notifications",
            dimensions: []
        )
    }

    func inboxSizeRecorder() -> any RecorderHandler {
        metricsFactory.makeRecorder(
            label: "inbox_size",
            dimensions: [],
            aggregate: true
        )
    }
}
