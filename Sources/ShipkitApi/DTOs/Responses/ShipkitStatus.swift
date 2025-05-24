//
//  ShipkitStatus.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/24/25.
//

/// Represents a top-level status for a shipment
enum ShipkitStatus: String, RawRepresentable, CaseIterable, Codable {
    case infoReceived
    case inTransit
    case outForDelivery
    case attemptFail
    case delivered
    case availableForPickup
    case exception
    case expired
    case pending
    case unknown
}
