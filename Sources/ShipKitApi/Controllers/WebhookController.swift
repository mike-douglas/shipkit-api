//
//  WebhookController.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/24/25.
//

import Vapor

struct WebhookController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let webhooks = routes.grouped("webhooks")

        try webhooks.register(collection: AfterShipWebhookController())
        try webhooks.register(collection: SeventeenTrackWebhookController())
        try webhooks.register(collection: MailgunWebhookController())
    }
}
