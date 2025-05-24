//
//  ShipkitUserInboxItem.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/24/25.
//

import struct Foundation.Date

/// Represents a shipment that is being tracked that came in from automated means (such as a Webhook)
struct ShipkitUserInboxItem: Codable {
    let id: String
    let trackingNumber: String
    let receivedAt: Date
}
