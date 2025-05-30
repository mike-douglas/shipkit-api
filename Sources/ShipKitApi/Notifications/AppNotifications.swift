//
//  AppNotifications.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/28/25.
//

import APNS
import APNSCore
import Vapor

struct AppNotifications {
    let apnsConfig: APNSClientConfiguration
    let topic: String

    static let shared: AppNotifications = {
        do {
            return try .init()
        } catch {
            fatalError("Failed to initialize AppNotifications: \(error)")
        }
    }()

    init() throws {
        guard let apnsPrivateKeyFile = Environment.process.APNS_PRIVATE_KEY_FILE else {
            fatalError("APNS_PRIVATE_KEY_FILE environment variable not set")
        }

        guard let apnsKeyIdentifier = Environment.process.APNS_KEY_IDENTIFIER else {
            fatalError("APNS_KEY_IDENTIFIER environment variable not set")
        }

        guard let apnsTeamIdentifier = Environment.process.APNS_TEAM_IDENTIFIER else {
            fatalError("APNS_TEAM_IDENTIFIER environment variable not set")
        }

        guard let apnsEnvironment = Environment.process.APNS_ENVIRONMENT else {
            fatalError("APNS_ENVIRONMENT environment variable not set")
        }

        guard let apnsTopic = Environment.process.APNS_TOPIC else {
            fatalError("APNS_TOPIC environment variable not set")
        }

        let keyFileContent = try String(contentsOfFile: apnsPrivateKeyFile, encoding: .utf8)

        topic = apnsTopic

        apnsConfig = try .init(
            authenticationMethod: .jwt(
                privateKey: .loadFrom(string: keyFileContent),
                keyIdentifier: apnsKeyIdentifier,
                teamIdentifier: apnsTeamIdentifier
            ),
            environment: apnsEnvironment == "development" ? .development : .production
        )
    }
}
