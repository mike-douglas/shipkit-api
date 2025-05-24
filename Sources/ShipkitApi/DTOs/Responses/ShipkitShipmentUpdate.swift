//
//  ShipkitShipmentUpdate.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/23/25.
//

import struct Foundation.Date
import struct Foundation.UUID

/// Represents a status update for a shipment being tracked by ShipKit
struct ShipkitShipmentUpdate: Codable {
    let id: UUID

    let title: String
    let comment: String
    let status: ShipkitStatus
    let substatus: ShipkitSubstatus
    let city: String?
    let state: String?
    let zip: String?
    let country: String?

    let latitude: Double?
    let longitude: Double?

    let timestamp: Date

    init(id: UUID, title: String, comment: String, status: ShipkitStatus, substatus: ShipkitSubstatus, city: String? = nil, state: String? = nil, zip: String? = nil, country: String? = nil, latitude: Double? = nil, longitude: Double? = nil, timestamp: Date) {
        self.id = id
        self.title = title
        self.comment = comment
        self.status = status
        self.substatus = substatus
        self.city = city
        self.state = state
        self.zip = zip
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }
}
