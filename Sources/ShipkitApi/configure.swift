import Fluent
import FluentSQLiteDriver
import Metrics
import NIOSSL
import Prometheus
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    MetricsSystem.bootstrap(AppMetrics.shared.metricsFactory)

    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)
    app.caches.use(.memory)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateReceivedShipments())

    try routes(app)
}
