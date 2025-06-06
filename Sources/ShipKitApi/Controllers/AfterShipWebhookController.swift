//
//  AfterShipWebhookController.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/24/25.
//

import AfterShip
import Fluent
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

struct AfterShipWebhookController: RouteCollection {
    private let hmacSecret: String

    init() {
        guard let hmacSecret: String = Environment.process.AFTERSHIP_WEBHOOK_SECRET else {
            fatalError("AFTERSHIP_WEBHOOK_SECRET environment variable not set")
        }

        self.hmacSecret = hmacSecret
    }

    func boot(routes: any RoutesBuilder) throws {
        let aftership = routes.grouped("aftership")

        aftership.post(use: incomingWebhook)
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
                req.logger.info("No userId found")
                throw Abort(.notFound)
            }

            guard let latestCheckpoint = shipment.checkpoints.sorted(by: { $0.createdAt > $1.createdAt }).first else {
                req.logger.info("No checkpoints found")
                throw Abort(.notFound)
            }

            if let userUUID = UUID(uuidString: userId),
               let user = try await User.find(userUUID, on: req.db)
            {
                let devices = try await user.$devices.query(on: req.db).all()

                req.logger.info("Sending notifications to \(user.mailbox) for \(shipment.id)")

                try await sendNotification(
                    title: shipment.title,
                    subtitle: latestCheckpoint.subtagMessage,
                    with: req,
                    to: devices.map { $0.deviceId }
                )

                AppMetrics.shared.notificationCounter().increment(by: 1)
            }
        } catch {
            req.logger.error("Error: \(error)")
            throw Abort(.internalServerError)
        }

        return .ok
    }
}
