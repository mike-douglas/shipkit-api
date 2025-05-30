//
//  AppSettingsController.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/28/25.
//

import ShipKitTypes
import Vapor

struct AppSettingsController: RouteCollection {
    let emailDomain: String

    init() {
        guard let emailDomain = Environment.process.SHIPKIT_EMAIL_DOMAIN else {
            fatalError("SHIPKIT_EMAIL_DOMAIN environment variable is not set")
        }

        self.emailDomain = emailDomain
    }

    func boot(routes: any RoutesBuilder) throws {
        let appSettings = routes.grouped(UserAuthenticator()).grouped("app")

        appSettings.get("settings", use: getAppSettings)
    }

    /// Return app settings configured from the server.
    ///
    /// - Parameter req: Request
    /// - Returns: App settings structure
    @Sendable
    func getAppSettings(req: Request) async throws -> ShipKitAppSettings {
        _ = try req.auth.require(APIUser.self)

        return .init(
            emailDomain: emailDomain
        )
    }
}
