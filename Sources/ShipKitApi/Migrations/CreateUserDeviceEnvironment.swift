//
//  CreateUserDeviceEnvironment.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 6/6/25.
//

import Fluent
import SQLKit

struct CreateUserDeviceEnvironment: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let defaultValue = SQLColumnConstraintAlgorithm.default("production")

        try await database.schema("user_devices")
            .field("environment", .string, .sql(defaultValue), .required)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("user_devices")
            .deleteField("environment")
            .update()
    }
}
