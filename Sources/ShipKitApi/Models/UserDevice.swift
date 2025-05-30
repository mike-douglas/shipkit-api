//
//  UserDevice.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/27/25.
//

import Fluent
import ShipKitTypes

enum UserDeviceNotificationPreference: String, Codable {
    case allUpdates
}

final class UserDevice: Model, @unchecked Sendable {
    static let schema = "user_devices"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "deviceId")
    var deviceId: String

    @Field(key: "notificationPreference")
    var notificationPreference: UserDeviceNotificationPreference

    @Parent(key: "userId")
    var user: User
}

extension UserDevice {
    func toDTO(on _: any Database) async throws -> ShipKitUserDevice {
        .init(
            deviceId: deviceId,
            notificationPreference: .init(rawValue: notificationPreference.rawValue)!
        )
    }
}
