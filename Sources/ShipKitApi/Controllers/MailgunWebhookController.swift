//
//  MailgunWebhookController.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/26/25.
//

import AfterShip
import Fluent
import SwiftEmailValidator
import Vapor

private struct MailgunWebhookMessage: Content, Codable {
    let signature: String
    let recipient: String
    let sender: String
    let from: String
    let subject: String
    let bodyHtml: String?
    let bodyPlain: String?
    let strippedHtml: String?
    let strippedText: String?
    let timestamp: Int
    let token: String

    enum CodingKeys: String, CodingKey {
        case signature,
             recipient,
             sender,
             from,
             subject,
             bodyHtml = "body-html",
             bodyPlain = "body-plain",
             strippedText = "stripped-text",
             strippedHtml = "stripped-html",
             timestamp,
             token
    }
}

struct MailgunWebhookController: RouteCollection {
    private let afterShipClient: AfterShipClient
    private let emailParser: EmailParser

    init() {
        guard let apiKey = Environment.process.AFTERSHIP_API_KEY else {
            fatalError("AFTERSHIP_API_KEY environment variable not set")
        }

        guard let orinocoApiUrlString = Environment.process.ORINOCO_API_URL else {
            fatalError("ORINOCO_API_URL environment variable not set")
        }

        afterShipClient = AfterShipClient(apiKey: apiKey)
        emailParser = EmailParser(clientUrl: URL(string: orinocoApiUrlString)!)
    }

    func boot(routes: any RoutesBuilder) throws {
        let mailgun = routes.grouped("mailgun")

        // Set max body size to 10mb for emails coming in
        mailgun.on(
            .POST,
            body: .collect(maxSize: "10mb"),
            use: incomingWebhook
        )
    }

    /// Handle incoming Mailgun webhook.
    ///
    /// This will start tracking new packages when a tracking number is found in the email body.
    ///
    /// - Parameter req: Request
    /// - Returns: HTTP Status or error
    @Sendable
    func incomingWebhook(req: Request) async throws -> HTTPStatus {
        do {
            let message = try req.content.decode(MailgunWebhookMessage.self)
            let recipient: String

            // Validate e-mail and message body
            guard let mailboxInfo = EmailSyntaxValidator.mailbox(from: message.recipient) else {
                throw Abort(.badRequest, reason: "Invalid recipient email address")
            }

            guard let body = message.bodyPlain else {
                throw Abort(.badRequest, reason: "Missing email body")
            }

            switch mailboxInfo.localPart {
            case let .dotAtom(string):
                recipient = string
            case let .quotedString(string):
                recipient = string
            }

            req.logger.info("Received message for: \(recipient)")

            // Look up the user by their mailbox
            guard let user = try await User.query(on: req.db)
                .filter(\.$mailbox == recipient)
                .first()
            else {
                throw Abort(.notFound, reason: "User not found")
            }

            if let trackingInfo = try await emailParser.detectTrackingFromEmail(body),
               let trackingNumber = trackingInfo.first?.trackingNumber,
               let title = trackingInfo.first?.title
            {
                req.logger.info("Detected tracking number: \(trackingNumber)")

                guard let shipment = try await afterShipClient.createTracking(
                    trackingNumber: trackingNumber,
                    title: title,
                    customFields: ["userId": user.id!.uuidString]
                ) else {
                    throw Abort(.internalServerError, reason: "Create tracking error")
                }

                let shipmentId = shipment.id

                // Create a new shipment record
                let newShipment = ReceivedShipment()

                newShipment.receivedAt = .now
                newShipment.shipmentId = shipmentId
                newShipment.trackingNumber = trackingNumber

                // Save to user
                try await user.$shipments.create(newShipment, on: req.db)

                AppMetrics.shared.packagesCounter(source: .email).increment(by: 1)
            } else {
                req.logger.info("No tracking information found in email")
                // TODO: Track failure
            }
        } catch {
            req.logger.error("Error: \(error)")
            throw Abort(.internalServerError)
        }

        return .ok
    }
}
