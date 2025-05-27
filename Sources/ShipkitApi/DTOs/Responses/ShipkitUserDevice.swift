//
//  ShipkitUserDevice.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/27/25.
//

struct ShipkitUserDevice: Codable {
    let deviceId: String
    let notificationPreference: ShipkitDeviceNotificationPreference
}
