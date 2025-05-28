import Fluent
import struct Foundation.UUID

final class User: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "mailbox")
    var mailbox: String

    @Children(for: \.$user)
    var devices: [UserDevice]

    @Children(for: \.$user)
    var shipments: [ReceivedShipment]
}

extension User {
    func toDTO(on database: any Database) async throws -> ShipkitUser {
        var deviceDTOs: [ShipkitUserDevice] = []

        for device in try await $devices.query(on: database).all() {
            try deviceDTOs.append(await device.toDTO(on: database))
        }

        return .init(
            id: id!,
            mailbox: mailbox,
            devices: deviceDTOs
        )
    }
}
