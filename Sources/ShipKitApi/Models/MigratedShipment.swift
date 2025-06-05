//
//  MigratedShipment.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 6/5/25.
//

import Fluent
import struct Foundation.UUID
import ShipKitTypes
import Vapor

final class MigratedShipment: Model, @unchecked Sendable {
    static let schema = "migrated_shipments"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "shipmentId")
    var shipmentId: ShipKitShipmentId

    @Field(key: "trackingNumber")
    var trackingNumber: String
}

extension MigratedShipment: Content {}
