//
//  CreateMigratedShipments.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 6/5/25.
//

import Fluent

struct CreateMigratedShipments: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("migrated_shipments")
            .id()
            .field("shipmentId", .string, .required)
            .field("trackingNumber", .string, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("migrated_shipments").delete()
    }
}
