import Fluent
import Metrics
import Prometheus
import Vapor

func routes(_ app: Application) throws {
    app.get("metrics") { _ async throws -> String in
        guard let metricsFactory = MetricsSystem.factory as? PrometheusMetricsFactory else {
            throw Abort(.notImplemented)
        }

        var buffer = [UInt8]()
        buffer.reserveCapacity(1024)

        metricsFactory.registry.emit(into: &buffer)
        return String(decoding: buffer, as: UTF8.self)
    }

    try app.register(collection: UserController())
    try app.register(collection: WebhookController())
}
