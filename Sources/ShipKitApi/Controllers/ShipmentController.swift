//
//  ShipmentController.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/22/25.
//

import AfterShip
import Fluent
import ShipKitTypes
import Vapor

struct ShipmentController: RouteCollection {
    private let client: AfterShipClient

    init() {
        guard let apiKey = Environment.process.AFTERSHIP_API_KEY else {
            fatalError("AFTERSHIP_API_KEY environment variable not set")
        }

        client = AfterShipClient(apiKey: apiKey)
    }

    func boot(routes: any RoutesBuilder) throws {
        let shipments = routes.grouped("tracking")

        shipments.post(use: startTracking)
        shipments.get("carrier", use: detectCarrierForTracking)
        shipments.group(":shipmentId") { shipment in
            shipment.get(use: self.getLatestTrackingUpdates)
        }
    }

    /// Create a new shipment and register it with the shipment tracker.
    ///
    /// - Parameter req: Request
    /// - Returns: HTTP Status
    @Sendable
    func startTracking(req: Request) async throws -> ShipKitShipment {
        _ = try req.auth.require(APIUser.self)

        guard let userId = req.parameters.get("userId") else {
            throw Abort(.badRequest)
        }

        let customFields = ["userId": userId]
        let trackingRequest = try req.content.decode(ShipKitTrackingRequest.self)

        do {
            if let trackingResponse = try await client.createTracking(
                trackingNumber: trackingRequest.trackingNumber,
                title: trackingRequest.title,
                customFields: customFields
            ) {
                AppMetrics.shared.packagesCounter(source: .api).increment(by: 1)
                return trackingResponse.toDTO()
            } else {
                throw Abort(.internalServerError)
            }
        } catch {
            req.logger.error("Error creating shipment: \(error)")
            throw Abort(.internalServerError)
        }
    }

    @Sendable
    func updateTracking(req _: Request) async throws -> HTTPStatus {
        return .notImplemented
    }

    /// Get the latest update for a shipment.
    ///
    /// - Parameter req: Request
    /// - Returns: HTTP Status
    @Sendable
    func getLatestTrackingUpdates(req: Request) async throws -> ShipKitShipment {
        _ = try req.auth.require(APIUser.self)

        guard let shipmentId = req.parameters.get("shipmentId") else {
            throw Abort(.badRequest)
        }

        // Check cache
        if let cacheEntry = try await req.application.cache.get("getLatestTrackingUpdates.\(shipmentId)", as: ShipKitShipment.self) {
            return cacheEntry
        }

        do {
            if let trackingResponse = try await client.getTracking(shipmentId) {
                let response = trackingResponse.toDTO()

                // Do not cache responses that have no updates
                if !trackingResponse.checkpoints.isEmpty {
                    try await req.application.cache.set(
                        "getLatestTrackingUpdates.\(shipmentId)",
                        to: response,
                        expiresIn: .seconds(300)
                    )
                }

                return response
            } else {
                throw Abort(.internalServerError)
            }
        } catch {
            req.logger.error("Error getting shipment: \(error)")
            throw Abort(.internalServerError)
        }
    }

    @Sendable
    func detectCarrierForTracking(req: Request) async throws -> [ShipKitCarrier] {
        _ = try req.auth.require(APIUser.self)

        let carrierDetectRequest = try req.query.decode(ShipKitCarrierDetectionRequest.self)

        guard let trackingNumber = carrierDetectRequest.trackingNumber else {
            throw Abort(
                .custom(
                    code: HTTPStatus.badRequest.code,
                    reasonPhrase: "trackingNumber is required"
                )
            )
        }

        // Check cache
        if let cacheEntry = try await req.application.cache.get("detectCarrierForTracking.\(trackingNumber)", as: [ShipKitCarrier].self) {
            return cacheEntry
        }

        do {
            if let carrierDetectResponse = try await client.detectCarrier(withTrackingNumber: trackingNumber) {
                let response = carrierDetectResponse.map { $0.toDTO() }

                try await req.application.cache.set(
                    "detectCarrierForTracking.\(trackingNumber)",
                    to: response,
                    expiresIn: .seconds(10)
                )

                return response
            } else {
                throw Abort(.internalServerError)
            }
        } catch {
            req.logger.error("Error getting shipment: \(error)")
            throw Abort(.internalServerError)
        }
    }
}
