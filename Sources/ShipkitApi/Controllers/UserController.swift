//
//  UserController.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/22/25.
//

import Fluent
import Vapor

extension ShipkitUser: Content, @unchecked Sendable {
    func toModel() -> User {
        let model = User()

        model.id = id
        model.mailbox = mailbox

        return model
    }
}

extension ShipkitUserInboxItem: Content, @unchecked Sendable {}

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped(UserAuthenticator()).grouped("user")

        users.post("", use: registerUser)

        try users.group(":userId") { user in
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
    func registerUser(req: Request) async throws -> ShipkitUser {
        _ = try req.auth.require(APIUser.self)

        let user = User()

        user.mailbox = generateRandomString(length: 8).lowercased()

        try await user.save(on: req.db)

        return user.toDTO()
    }

    /// Update the user's settings (push notifications, etc.).
    ///
    /// - Parameter req: Request
    /// - Returns: HTTP Status
    @Sendable
    func updateSettings(req _: Request) async throws -> HTTPStatus {
        .notImplemented
    }

    @Sendable
    func getUserInbox(req: Request) async throws -> [ShipkitUserInboxItem] {
        _ = try req.auth.require(APIUser.self)

        guard let user = try await User.find(req.parameters.get("userId"), on: req.db) else {
            throw Abort(.notFound)
        }

        return try await user.$shipments.query(on: req.db).all().map {
            $0.toDTO()
        }
    }
}
