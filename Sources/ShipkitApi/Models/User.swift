import Fluent
import struct Foundation.UUID

final class User: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "mailbox")
    var mailbox: String

    @Children(for: \.$user)
    var shipments: [ReceivedShipment]

    func toDTO() -> ShipkitUser {
        .init(
            id: id!,
            mailbox: mailbox
        )
    }
}
