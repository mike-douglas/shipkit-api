//
//  ShipmentController.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/22/25.
//

import AfterShip
import Fluent
import Vapor

extension ShipkitShipment: Content, @unchecked Sendable {}
extension ShipkitShipmentUpdate: Content, @unchecked Sendable {}
extension ShipkitCarrier: Content, @unchecked Sendable {}

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
    func startTracking(req: Request) async throws -> ShipkitShipment {
        _ = try req.auth.require(APIUser.self)

        let trackingRequest = try req.content.decode(ShipkitTrackingRequest.self)

        do {
            if let trackingResponse = try await client.createTracking(trackingNumber: trackingRequest.trackingNumber) {
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
    func getLatestTrackingUpdates(req: Request) async throws -> ShipkitShipment {
        _ = try req.auth.require(APIUser.self)

        guard let shipmentId = req.parameters.get("shipmentId") else {
            throw Abort(.badRequest)
        }

        // Check cache
        if let cacheEntry = try await req.application.cache.get("getLatestTrackingUpdates.\(shipmentId)", as: ShipkitShipment.self) {
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
    func detectCarrierForTracking(req: Request) async throws -> [ShipkitCarrier] {
        _ = try req.auth.require(APIUser.self)

        let carrierDetectRequest = try req.query.decode(ShipkitCarrierDetectionRequest.self)

        guard let trackingNumber = carrierDetectRequest.trackingNumber else {
            throw Abort(
                .custom(
                    code: HTTPStatus.badRequest.code,
                    reasonPhrase: "trackingNumber is required"
                )
            )
        }

        // Check cache
        if let cacheEntry = try await req.application.cache.get("detectCarrierForTracking.\(trackingNumber)", as: [ShipkitCarrier].self) {
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
