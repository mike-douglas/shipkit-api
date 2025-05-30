import Fluent
import FluentSQLiteDriver
import Metrics
import NIOSSL
import Prometheus
import Redis
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

    // Set up Redis connection
    guard let celeryBroker = Environment.process.CELERY_BROKER_URL else {
        fatalError("CELERY_BROKER_URL environment variable not set")
    }

    guard let celeryResultBackend = Environment.process.CELERY_RESULT_BACKEND else {
        fatalError("CELERY_RESULT_BACKEND environment variable not set")
    }

    app.redis.configuration = try RedisConfiguration(hostname: celeryBroker)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateReceivedShipments())
    app.migrations.add(CreateUserDevice())

    try routes(app)
}
