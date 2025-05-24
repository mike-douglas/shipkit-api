//
//  WebhookController.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/24/25.
//

import Vapor

struct WebhookController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let webhooks = routes.grouped("webhooks")

        try webhooks.register(collection: AfterShipWebhookController())
    }
}
