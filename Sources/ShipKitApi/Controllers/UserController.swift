//
//  UserController.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/22/25.
//

import Fluent
import ShipKitTypes
import Vapor

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

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped(UserAuthenticator()).grouped("user")

        users.post(use: registerUser)

        try users.group(":userId") { user in
            user.put(use: updateSettings)
            user.get("shipments", use: getUserInbox)

            try user.register(collection: ShipmentController())
        }
    }

    private func generateRandomString(length: Int = 10) -> String {
        // Ensure the length does not exceed 10
        let maxLength = min(length, 10)

        // Generate a UUID and convert it to a string
        let uuid = UUID().uuidString

        // Remove dashes and truncate to the desired length
        let randomString = uuid.replacingOccurrences(of: "-", with: "").prefix(maxLength)

        return String(randomString)
    }

    /// Register a new user
    ///
    /// - Parameter req: Request
    /// - Returns: The created users, with ID and mailbox
    @Sendable
    func registerUser(req: Request) async throws -> ShipKitUser {
        _ = try req.auth.require(APIUser.self)

        let user = User()

        user.mailbox = generateRandomString(length: 8).lowercased()

        try await user.save(on: req.db)

        return try await user.toDTO(on: req.db)
    }

    /// Update the user's settings (push notifications, etc.).
    ///
    /// - Parameter req: Request
    /// - Returns: HTTP Status
    @Sendable
    func updateSettings(req: Request) async throws -> ShipKitUser {
        _ = try req.auth.require(APIUser.self)

        guard let user = try await User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }

        let updateRequest = try req.content.decode(ShipKitUpdateUserRequest.self)

        for deviceUpdate in updateRequest.user.devices {
            if let device = try await user.$devices.query(on: req.db).filter(\.$deviceId == deviceUpdate.deviceId).first() {
                if let notificationPreference = UserDeviceNotificationPreference(rawValue: deviceUpdate.notificationPreference.rawValue) {
                    device.notificationPreference = notificationPreference
                }

                try await device.save(on: req.db)
            } else {
                let newDevice = UserDevice()

                newDevice.deviceId = deviceUpdate.deviceId
                newDevice.notificationPreference = .init(rawValue: deviceUpdate.notificationPreference.rawValue) ?? .allUpdates

                try await user.$devices.create(newDevice, on: req.db)
            }
        }

        return try await user.toDTO(on: req.db)
    }

    @Sendable
    func getUserInbox(req: Request) async throws -> [ShipKitUserInboxItem] {
        _ = try req.auth.require(APIUser.self)

        guard let user = try await User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }

        var shipmentDTOs: [ShipKitUserInboxItem] = []

        for shipment in try await user.$shipments.query(on: req.db).all() {
            try shipmentDTOs.append(await shipment.toDTO(on: req.db))
        }

        return shipmentDTOs
    }
}
