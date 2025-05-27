//
//  AppMetrics.swift
//  ShipkitApi
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
    let metricsFactory: PrometheusMetricsFactory

    static let shared: AppMetrics = .init()

    init() {
        metricsFactory = PrometheusMetricsFactory(registry: PrometheusCollectorRegistry()
        )
    }

    func packagesCounter(source: PackageAddSource) -> any CounterHandler {
        metricsFactory.makeCounter(
            label: "packages",
            dimensions: [("source", source.rawValue)]
        )
    }
}
