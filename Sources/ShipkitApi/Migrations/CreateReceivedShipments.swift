//
//  CreateReceivedShipments.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/22/25.
//

import Fluent

struct CreateReceivedShipments: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("received_shipments")
            .id()
            .field("userId", .uuid, .required, .references("users", "id"))
            .field("shipmentId", .string, .required)
            .field("trackingNumber", .string, .required)
            .field("receivedAt", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("user_inbox_items").delete()
    }
}
