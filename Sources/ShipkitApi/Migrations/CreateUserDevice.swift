//
//  CreateUserDevice.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/27/25.
//

import Fluent

struct CreateUserDevice: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("user_devices")
            .id()
            .field("userId", .uuid, .required, .references("users", "id"))
            .field("deviceId", .string, .required)
            .field("notificationPreference", .string, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("user_devices").delete()
    }
}
