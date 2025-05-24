//
//  ShipkitShipment.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/23/25.
//

import struct Foundation.Date
import struct Foundation.UUID

/// Represents a shipment being tracked by ShipKit
struct ShipkitShipment: Codable {
    let id: String

    let title: String
    let trackingNumber: String
    let carrier: String

    let updates: [ShipkitShipmentUpdate]

    let deliveryDate: Date?
    let timestamp: Date?

    init(id: String, title: String, trackingNumber: String, carrier: String, updates: [ShipkitShipmentUpdate] = [], deliveryDate: Date? = nil, timestamp: Date? = nil) {
        self.id = id
        self.title = title
        self.trackingNumber = trackingNumber
        self.carrier = carrier
        self.updates = updates
        self.deliveryDate = deliveryDate
        self.timestamp = timestamp
    }
}
