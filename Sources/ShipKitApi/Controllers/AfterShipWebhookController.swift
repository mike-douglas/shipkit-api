//
//  AfterShipWebhookController.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/24/25.
//

import AfterShip
import Fluent
import ShipKitTypes
import Vapor

/// Represents a message received from AfterShip
private struct ASWebhookEvent: Codable, Content {
    let event: String
    let eventId: UUID
    let isTrackingFirstTag: Bool
    let msg: ASTracking
    let ts: Int64

    enum CodingKeys: String, CodingKey {
        case event
        case eventId = "event_id"
        case isTrackingFirstTag = "is_tracking_first_tag"
        case msg
        case ts
    }
}

private struct NotificationMessage: Codable, Content {
    let shipmentId: ShipKitShipmentId
    let userId: ShipKitUserId
}

struct AfterShipWebhookController: RouteCollection {
    private let hmacSecret: String
    private let afterShipClient: AfterShipClient

    init() {
        guard let apiKey = Environment.process.AFTERSHIP_API_KEY else {
            fatalError("AFTERSHIP_API_KEY environment variable not set")
        }

        guard let hmacSecret: String = Environment.process.AFTERSHIP_WEBHOOK_SECRET else {
            fatalError("AFTERSHIP_WEBHOOK_SECRET environment variable not set")
        }

        self.hmacSecret = hmacSecret
        afterShipClient = .init(apiKey: apiKey)
    }

    func boot(routes: any RoutesBuilder) throws {
        let aftership = routes.grouped("aftership")

        aftership.post(use: incomingWebhook)
        aftership.grouped(UserAuthenticator()).post("notify", use: sendNotificationTest)
    }

    @Sendable
    func sendNotificationTest(req: Request) async throws -> HTTPStatus {
        _ = try req.auth.require(APIAdmin.self)

        let message = try req.content.decode(NotificationMessage.self)

        guard let user = try await User.find(message.userId, on: req.db) else {
            req.logger.error("Could not find user \(message.userId)")
            throw Abort(.notFound)
        }

        guard let shipment = try await afterShipClient.getTracking(message.shipmentId) else {
            req.logger.error("Could not find shipment \(message.shipmentId)")
            throw Abort(.notFound)
        }

        guard let latestCheckpoint = shipment.checkpoints.sorted(by: { $0.createdAt > $1.createdAt }).first else {
            req.logger.error("No checkpoints found")
            throw Abort(.notFound)
        }

        let devices = try await user.$devices.query(on: req.db).all()

        req.logger.info("Sending notifications to \(user.mailbox) for \(shipment.id) to \(devices.map { [$0.deviceId, $0.environment.rawValue].joined(separator: ":") })")

        try await sendNotification(
            title: shipment.title,
            subtitle: latestCheckpoint.subtagMessage,
            with: req,
            to: devices.map { $0.deviceId }
        )

        AppMetrics.shared.notificationCounter().increment(by: 1)

        return .ok
    }

    /// Handle incoming AfterShip API webhook.
    ///
    /// This will send a notification to the user that an update is available for their shipment.
    ///
    /// - Parameter req: Request
    /// - Returns: HTTP Status or error
    @Sendable
    func incomingWebhook(req: Request) async throws -> HTTPStatus {
        guard let hmacAuth = req.headers.first(name: "Aftership-Hmac-Sha256") else {
            return .unauthorized
        }

        guard let requestBody = req.body.string else {
            return .badRequest
        }

        let signature = hmacSha256(
            data: requestBody,
            secret: hmacSecret
        )

        guard let signature, hmacAuth == signature else {
            return .unauthorized
        }

        do {
            let message = try req.content.decode(ASWebhookEvent.self)
            let shipment = message.msg

            req.logger.info("Update received for: \(shipment.id), \(shipment.trackingNumber)")

            guard let userId = shipment.customFields?["userId"] else {
                req.logger.error("No userId found")
                throw Abort(.notFound)
            }

            guard let latestCheckpoint = shipment.checkpoints.sorted(by: { $0.createdAt > $1.createdAt }).first else {
                req.logger.error("No checkpoints found")
                throw Abort(.notFound)
            }

            if let userUUID = UUID(uuidString: userId),
               let user = try await User.find(userUUID, on: req.db)
            {
                let devices = try await user.$devices.query(on: req.db).all()

                req.logger.info("Sending notifications to \(user.mailbox) for \(shipment.id) to \(devices.map { [$0.deviceId, $0.environment.rawValue].joined(separator: ":") })")

                try await sendNotification(
                    title: shipment.title,
                    subtitle: latestCheckpoint.subtagMessage,
                    with: req,
                    to: devices.map { $0.deviceId }
                )

                AppMetrics.shared.notificationCounter().increment(by: 1)
            } else {
                req.logger.error("User \(userId) not found")
                throw Abort(.notFound)
            }
        } catch {
            req.logger.error("Error: \(error)")
            throw Abort(.internalServerError)
        }

        return .ok
    }
}
