//
//  SeventeenTrackWebhookController.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 7/30/25.
//

import Fluent
import SeventeenTrack
import ShipKitTypes
import Vapor

private struct NotificationMessage: Codable, Content {
    let shipmentId: ShipKitShipmentId
    let userId: ShipKitUserId
}

struct SeventeenTrackWebhookController: RouteCollection {
    private let seventeenTrackClient: SeventeenTrackClient

    init() {
        guard let apiKey = Environment.process.SEVENTEENTRACK_API_KEY else {
            fatalError("SEVENTEENTRACK_API_KEY environment variable not set")
        }

        seventeenTrackClient = .init(apiKey: apiKey)
    }

    func boot(routes: any RoutesBuilder) throws {
        let aftership = routes.grouped("17track")

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

        guard let shipment = try await seventeenTrackClient.getTracking(message.shipmentId) else {
            req.logger.error("Could not find shipment \(message.shipmentId)")
            throw Abort(.notFound)
        }

        guard let latestCheckpoint = shipment.updates.sorted(by: { $0.timestamp > $1.timestamp }).first else {
            req.logger.error("No updates found")
            throw Abort(.notFound)
        }

        let devices = try await user.$devices.query(on: req.db).all()

        req.logger.info("Sending notifications to \(user.mailbox) for \(shipment.id) to \(devices.map { [$0.deviceId, $0.environment.rawValue].joined(separator: ":") })")

        try await sendNotification(
            title: shipment.title,
            subtitle: latestCheckpoint.substatus.localizedString,
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
        guard req.body.string != nil else {
            return .badRequest
        }

        do {
            let message = try req.content.decode(SeventeenTrackWebhookResponse.self)
            let shipment = message.data.shipKitShipment

            req.logger.info("Update received for: \(shipment.id), \(shipment.trackingNumber)")

            guard let userId = shipment.userId else {
                req.logger.error("No userId found")
                return .accepted
            }

            guard let latestCheckpoint = shipment.updates.sorted(by: { $0.timestamp > $1.timestamp }).first else {
                req.logger.error("No updates found")
                return .accepted
            }

            if let user = try await User.find(userId, on: req.db) {
                let devices = try await user.$devices.query(on: req.db).all()

                req.logger.info("Sending notifications to \(user.mailbox) for \(shipment.id) to \(devices.map { [$0.deviceId, $0.environment.rawValue].joined(separator: ":") })")
                req.logger.info("Checkpoint: \(latestCheckpoint.status.localizedString), \(latestCheckpoint.substatus.localizedString)")

                let updateDTO = latestCheckpoint

                try await sendNotification(
                    title: shipment.title,
                    subtitle: updateDTO.substatus.localizedString,
                    with: req,
                    to: devices.map { $0.deviceId }
                )

                AppMetrics.shared.notificationCounter().increment(by: 1)
            } else {
                req.logger.error("User \(userId) not found")
                return .accepted
            }
        } catch {
            req.logger.error("Error: \(error)")
            throw Abort(.internalServerError)
        }

        return .ok
    }
}
