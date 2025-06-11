//
//  ShipKitTypes+Vapor.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/30/25.
//

import ShipKitTypes
import Vapor

extension ShipKitAppSettings: @retroactive AsyncResponseEncodable {}
extension ShipKitAppSettings: @retroactive AsyncRequestDecodable {}
extension ShipKitAppSettings: @retroactive ResponseEncodable {}
extension ShipKitAppSettings: @retroactive RequestDecodable {}
extension ShipKitAppSettings: @retroactive Content, @unchecked @retroactive Sendable {}

extension ShipKitShipment: @retroactive AsyncResponseEncodable {}
extension ShipKitShipment: @retroactive AsyncRequestDecodable {}
extension ShipKitShipment: @retroactive ResponseEncodable {}
extension ShipKitShipment: @retroactive RequestDecodable {}
extension ShipKitShipment: @retroactive Content, @unchecked @retroactive Sendable {}

extension ShipKitShipmentUpdate: @retroactive AsyncResponseEncodable {}
extension ShipKitShipmentUpdate: @retroactive AsyncRequestDecodable {}
extension ShipKitShipmentUpdate: @retroactive ResponseEncodable {}
extension ShipKitShipmentUpdate: @retroactive RequestDecodable {}
extension ShipKitShipmentUpdate: @retroactive Content, @unchecked @retroactive Sendable {}

extension ShipKitCarrier: @retroactive AsyncResponseEncodable {}
extension ShipKitCarrier: @retroactive AsyncRequestDecodable {}
extension ShipKitCarrier: @retroactive ResponseEncodable {}
extension ShipKitCarrier: @retroactive RequestDecodable {}
extension ShipKitCarrier: @retroactive Content, @unchecked @retroactive Sendable {}

extension ShipKitUser: @retroactive AsyncResponseEncodable {}
extension ShipKitUser: @retroactive AsyncRequestDecodable {}
extension ShipKitUser: @retroactive ResponseEncodable {}
extension ShipKitUser: @retroactive RequestDecodable {}

extension ShipKitUser: @retroactive Content, @unchecked @retroactive Sendable {
    func toModel() -> User {
        let model = User()

        model.id = id
        model.mailbox = mailbox

        return model
    }
}

extension ShipKitUserInboxItem: @retroactive AsyncResponseEncodable {}
extension ShipKitUserInboxItem: @retroactive AsyncRequestDecodable {}
extension ShipKitUserInboxItem: @retroactive ResponseEncodable {}
extension ShipKitUserInboxItem: @retroactive RequestDecodable {}
extension ShipKitUserInboxItem: @retroactive Content, @unchecked @retroactive Sendable {}

extension ShipKitUserDevice: @retroactive Content, @unchecked @retroactive Sendable {
    func toModel() -> UserDevice {
        let model = UserDevice()

        model.deviceId = deviceId
        model.notificationPreference = UserDeviceNotificationPreference(rawValue: notificationPreference.rawValue)!
        model.environment = UserDeviceNotificationEnvironment(rawValue: environment.rawValue)!

        return model
    }
}

extension ShipKitShipmentIdLookup: @retroactive AsyncResponseEncodable {}
extension ShipKitShipmentIdLookup: @retroactive AsyncRequestDecodable {}
extension ShipKitShipmentIdLookup: @retroactive ResponseEncodable {}
extension ShipKitShipmentIdLookup: @retroactive RequestDecodable {}
extension ShipKitShipmentIdLookup: @retroactive Content, @unchecked @retroactive Sendable {}
