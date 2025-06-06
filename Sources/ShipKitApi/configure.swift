import Fluent
import FluentSQLiteDriver
import Metrics
import NIOSSL
import Prometheus
import Vapor
import VaporAPNS

// configures your application
public func configure(_ app: Application) async throws {
    // Set up metrics
    MetricsSystem.bootstrap(AppMetrics.shared.metricsFactory)

    // Set up notifications
    app.apns.containers.use(
        AppNotifications.shared.apnsConfig,
        eventLoopGroupProvider: .shared(app.eventLoopGroup),
        responseDecoder: JSONDecoder(),
        requestEncoder: JSONEncoder(),
        as: .default
    )

    // Set up database
    guard let dbFile = Environment.process.SHIPKIT_SQLITE_DB_FILE else {
        fatalError("SHIPKIT_SQLITE_DB_FILE environment variable not set")
    }

    app.databases.use(DatabaseConfigurationFactory.sqlite(.file(dbFile)), as: .sqlite)
    app.caches.use(.memory)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateReceivedShipments())
    app.migrations.add(CreateMigratedShipments())
    app.migrations.add(CreateUserDevice())
    app.migrations.add(CreateUserDeviceEnvironment())

    try routes(app)
}
