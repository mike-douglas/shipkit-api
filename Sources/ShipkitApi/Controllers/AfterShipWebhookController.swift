//
//  AfterShipWebhookController.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/24/25.
//

import AfterShip
import CryptoKit
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
    func boot(routes: any RoutesBuilder) throws {
        let aftership = routes.grouped("aftership")

        aftership.post(use: incomingWebhook)
    }

    /// Generate a signature used to validate the authenticity of a request
    ///
    /// - Parameters:
    ///   - data: Data to sign
    ///   - secret: Secret to sign it with
    /// - Returns: A base64 string
    private func hmacSha256(data: String, secret: String) -> String? {
        let key = SymmetricKey(data: Data(secret.utf8))

        guard let dataToSign = data.data(using: .utf8) else {
            return nil
        }

        let signature = HMAC<SHA256>.authenticationCode(for: dataToSign, using: key)
        let hmacData = Data(signature)

        return hmacData.base64EncodedString()
    }

    /// Handle incoming AfterShip API webhook
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

        let secret = req.application.environment.AFTERSHIP_WEBHOOK_SECRET
        let signature = hmacSha256(data: requestBody, secret: secret)

        guard let signature, hmacAuth == signature else {
            return .unauthorized
        }

        do {
            let message = try req.content.decode(ASWebhookEvent.self)
            let shipment = message.msg

            req.logger.info("Update received for: \(shipment.id), \(shipment.trackingNumber)")

            // TODO: Send notifications
        } catch {
            req.logger.error("Error: \(error)")
            throw Abort(.internalServerError)
        }

        return .ok
    }
}
