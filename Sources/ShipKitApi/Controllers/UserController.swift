//
//  UserController.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/22/25.
//

import Fluent
import ShipKitTypes
import Vapor

struct UserController: RouteCollection {
    private let isTesting: Bool

    init() {
        isTesting = Environment.process.SHIPKIT_TEST_MODE == nil ? false : true
    }

    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped(UserAuthenticator()).grouped("user")

        users.post(use: registerUser)
        users.post("migrations", use: addMigratedUsers)

        try users.group(":userId") { user in
            user.put(use: updateSettings)

            if isTesting {
                user.get("shipments", use: getUserTestInbox)
            } else {
                user.get("shipments", use: getUserInbox)
            }

            user.post("shipments", use: addToUserInbox)

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

    /// Register a new user.
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
                newDevice.environment = deviceUpdate.environment == .production ? .production : .development

                try await user.$devices.create(newDevice, on: req.db)
            }
        }

        return try await user.toDTO(on: req.db)
    }

    /// Get all the items in the user's inbox, then delete them.
    ///
    /// - Parameter req: Request
    /// - Returns: Array of inbox items for the user
    @Sendable
    func getUserInbox(req: Request) async throws -> [ShipKitUserInboxItem] {
        _ = try req.auth.require(APIUser.self)

        guard let user = try await User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }

        var shipmentDTOs: [ShipKitUserInboxItem] = []

        for shipment in try await user.$shipments.query(on: req.db).all() {
            try shipmentDTOs.append(await shipment.toDTO(on: req.db))
            try await shipment.delete(on: req.db)
        }

        AppMetrics.shared.inboxSizeRecorder().record(Int64(shipmentDTOs.count))

        return shipmentDTOs
    }

    /// Get test user data
    ///
    /// - Parameter req: Request
    /// - Returns: Array of inbox items for the user
    @Sendable
    func getUserTestInbox(req: Request) async throws -> [ShipKitUserInboxItem] {
        _ = try req.auth.require(APIUser.self)

        let shipmentDTOs: [ShipKitUserInboxItem] = testShipments.map {
            .init(id: $0.id, trackingNumber: $0.trackingNumber, receivedAt: $0.timestamp!)
        }

        AppMetrics.shared.inboxSizeRecorder().record(Int64(shipmentDTOs.count))

        return shipmentDTOs
    }

    /// Add an item to the user inbox. This is an admin function.
    ///
    /// - Parameter req: Request
    /// - Returns: The item added
    @Sendable
    func addToUserInbox(req: Request) async throws -> ShipKitUserInboxItem {
        _ = try req.auth.require(APIAdmin.self)

        guard let user = try await User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }

        let inboxItem = try req.content.decode(ShipKitUserInboxItem.self)
        let receivedShipment = ReceivedShipment()

        receivedShipment.shipmentId = inboxItem.id
        receivedShipment.trackingNumber = inboxItem.trackingNumber
        receivedShipment.receivedAt = inboxItem.receivedAt

        try await user.$shipments.create(receivedShipment, on: req.db)

        return try await receivedShipment.toDTO(on: req.db)
    }

    /// Migration endpoint for users to help in v1->v2 migration. This is an admin function.
    ///
    /// - Parameter req: Request
    /// - Returns: HTTP Status
    @Sendable
    func addMigratedUsers(req: Request) async throws -> HTTPStatus {
        _ = try req.auth.require(APIAdmin.self)

        let usersToMigrate = try req.content.decode([ShipKitUser].self)

        for migratedUser in usersToMigrate {
            let user = migratedUser.toModel()

            try await user.create(on: req.db)

            for device in migratedUser.devices {
                try await user.$devices.create(device.toModel(), on: req.db)
            }
        }

        return .created
    }
}
