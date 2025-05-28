//
//  RouteCollection+SendNotification.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/28/25.
//

import APNS
import APNSCore
import Vapor
import VaporAPNS

extension RouteCollection {
    func sendNotification(title _: String, subtitle _: String, with request: Request, to tokens: [String]) async throws {
        let alert = APNSAlertNotification(
            alert: .init(
                title: .raw("Foo"),
                subtitle: .raw("Bar")
            ),
            expiration: .immediately,
            priority: .immediately,
            topic: ""
        )

        for token in tokens {
            try await request.apns.client.sendAlertNotification(
                alert,
                deviceToken: token
            )
        }
    }
}
