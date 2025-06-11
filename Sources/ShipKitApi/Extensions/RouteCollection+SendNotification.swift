//
//  RouteCollection+SendNotification.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/28/25.
//

import APNS
import APNSCore
import Vapor
import VaporAPNS

extension RouteCollection {
    func sendNotification(title: String, subtitle: String, with request: Request, to tokens: [String]) async throws {
        let alert = APNSAlertNotification(
            alert: .init(
                title: .raw(title),
                subtitle: .raw(subtitle)
            ),
            expiration: .immediately,
            priority: .immediately,
            topic: AppNotifications.shared.topic
        )

        for token in tokens {
            try await request.apns.client.sendAlertNotification(
                alert,
                deviceToken: token
            )
        }
    }
}
