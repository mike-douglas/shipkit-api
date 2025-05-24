//
//  AfterShipWebhookController.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/24/25.
//

import Fluent
import Vapor

struct AfterShipWebhookController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let aftership = routes.grouped("aftership")

        aftership.post(use: incomingWebhook)
    }

    /// Handle incoming AfterShip API webhook
    ///
    /// - Parameter req: Request
    /// - Returns: HTTP Status or error
    @Sendable
    func incomingWebhook(_: Request) async throws -> HTTPStatus {
        .notImplemented
    }
}
