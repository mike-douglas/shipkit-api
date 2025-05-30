//
//  ReceivedShipment.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/22/25.
//

import Fluent
import struct Foundation.Date
import struct Foundation.UUID
import ShipKitTypes

final class ReceivedShipment: Model, @unchecked Sendable {
    static let schema = "received_shipments"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "userId")
    var user: User

    @Field(key: "shipmentId")
    var shipmentId: String

    @Field(key: "trackingNumber")
    var trackingNumber: String

    @Field(key: "receivedAt")
    var receivedAt: Date
}

extension ReceivedShipment {
    func toDTO(on _: any Database) async throws -> ShipKitUserInboxItem {
        .init(
            id: shipmentId,
            trackingNumber: trackingNumber,
            receivedAt: receivedAt
        )
    }
}
