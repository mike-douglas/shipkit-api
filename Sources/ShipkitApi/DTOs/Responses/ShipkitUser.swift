//
//  ShipkitUser.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/22/25.
//

import struct Foundation.UUID

/// Represents a registered user in ShipKit
struct ShipkitUser: Codable {
    let id: UUID
    let mailbox: String
}
