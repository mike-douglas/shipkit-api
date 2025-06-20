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
    let offeringIdentifier: String

    init() {
        guard let emailDomain = Environment.process.SHIPKIT_EMAIL_DOMAIN else {
            fatalError("SHIPKIT_EMAIL_DOMAIN environment variable is not set")
        }

        guard let offeringIdentifier = Environment.process.SHIPKIT_ACTIVE_OFFERING_IDENTIFIER else {
            fatalError("SHIPKIT_ACTIVE_OFFERING_IDENTIFIER environment variable is not set")
        }

        self.offeringIdentifier = offeringIdentifier
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
            emailDomain: emailDomain,
            offeringIdentifier: offeringIdentifier
        )
    }
}
