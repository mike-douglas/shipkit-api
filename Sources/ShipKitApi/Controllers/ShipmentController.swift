//
//  ShipmentController.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/22/25.
//

import Fluent
import SeventeenTrack
import ShipKitTypes
import Vapor

struct ShipmentController: RouteCollection {
    private let client: SeventeenTrackClient
    private let isTesting: Bool

    init() {
        guard let apiKey = Environment.process.SEVENTEENTRACK_API_KEY else {
            fatalError("SEVENTEENTRACK_API_KEY environment variable not set")
        }

        isTesting = Environment.process.SHIPKIT_TEST_MODE == nil ? false : true

        client = SeventeenTrackClient(apiKey: apiKey)
    }

    func boot(routes: any RoutesBuilder) throws {
        let shipments = routes.grouped("tracking")

        shipments.post(use: startTracking)
        shipments.get("carrier", use: detectCarrierForTracking)

        // Migration endpoints for v1 endpoint
        shipments.get(use: findMigratedShipment)
        shipments.post("migrations", use: addMigratedShipments)

        shipments.group(":shipmentId") { shipment in
            if isTesting {
                shipment.get(use: self.geTestTrackingUpdates)
            } else {
                shipment.get(use: self.getLatestTrackingUpdates)
            }

            shipment.put(use: self.updateTracking)
            shipment.delete(use: self.stopTracking)
        }
    }

    /// Create a new shipment and register it with the shipment tracker.
    ///
    /// - Parameter req: Request
    /// - Returns: The Shipment
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
                customFields: customFields,
                carrierSlug: trackingRequest.carrierSlug
            ) {
                AppMetrics.shared.packagesCounter(source: .api).increment(by: 1)

                return trackingResponse
            } else {
                throw Abort(.internalServerError)
            }
        } catch let SeventeenTrackError.rejectedError(rejectError) {
            if rejectError == .carrierNotDetected {
                throw Abort(.notFound, reason: "Unable to detect carrier from tracking number")
            } else {
                throw Abort(.internalServerError)
            }
        } catch {
            req.logger.error("Error creating shipment: \(error)")
            throw Abort(.internalServerError)
        }
    }

    /// Update an existing shipment.
    ///
    /// - Parameter req: Request
    /// - Returns: The Shipment
    @Sendable
    func updateTracking(req: Request) async throws -> ShipKitShipment {
        _ = try req.auth.require(APIUser.self)

        guard let shipmentId = req.parameters.get("shipmentId") else {
            throw Abort(.badRequest)
        }

        let updateRequest = try req.content.decode(ShipKitUpdateShipmentRequest.self)
        var customFields: [String: String] = [:]

        if let userId = updateRequest.userId {
            customFields["userId"] = userId.uuidString
        }

        do {
            if let updateResponse = try await client.updateTracking(
                shipmentId,
                title: updateRequest.title,
                customFields: customFields,
                carrierSlug: updateRequest.carrier
            ) {
                return updateResponse
            } else {
                throw Abort(.internalServerError)
            }
        } catch {
            req.logger.error("Error updating shipment: \(error)")
            throw Abort(.internalServerError)
        }
    }

    /// Stop tracking a shipment (and no longer receive webhook updates).
    ///
    /// - Parameter req: Request
    /// - Returns: HTTP Status
    @Sendable
    func stopTracking(req: Request) async throws -> HTTPStatus {
        _ = try req.auth.require(APIUser.self)

        guard let shipmentId = req.parameters.get("shipmentId") else {
            throw Abort(.badRequest)
        }

        do {
            if try await client.deleteTracking(shipmentId) != nil {
                return .ok
            } else {
                throw Abort(.internalServerError)
            }
        } catch {
            req.logger.error("Error deleting shipment: \(error)")
            throw Abort(.internalServerError)
        }
    }

    /// Get the latest update for a shipment.
    ///
    /// - Parameter req: Request
    /// - Returns: The Shipment
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
                let response = trackingResponse

                // Do not cache responses that have no updates
                if !trackingResponse.updates.isEmpty {
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

    /// Get the latest update for a shipment.
    ///
    /// - Parameter req: Request
    /// - Returns: The Shipment
    @Sendable
    func geTestTrackingUpdates(req: Request) async throws -> ShipKitShipment {
        _ = try req.auth.require(APIUser.self)

        guard let shipmentId = req.parameters.get("shipmentId") else {
            throw Abort(.badRequest)
        }

        guard let shipmentRecord = testShipments.first(where: { $0.id == shipmentId }) else {
            throw Abort(.notFound)
        }

        return shipmentRecord
    }

    /// Detect the carrier for a shipment by tracking number.
    ///
    /// - Parameter req: Request
    /// - Returns: An Array of possible Carriers
    @Sendable
    func detectCarrierForTracking(req: Request) async throws -> [ShipKitCarrier] {
        _ = try req.auth.require(APIUser.self)

        let carrierDetectRequest = try req.query.decode(ShipKitCarrierDetectionRequest.self)

        guard let trackingNumber = carrierDetectRequest.trackingNumber else {
            return SeventeenTrackCarrier.allCarriers.values.map { $0 }
        }

        // Check cache
        if let cacheEntry = try await req.application.cache.get("detectCarrierForTracking.\(trackingNumber)", as: [ShipKitCarrier].self) {
            return cacheEntry
        }

        do {
            if let carrierDetectResponse = try await client.detectCarrier(withTrackingNumber: trackingNumber) {
                let response = carrierDetectResponse

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

    /// Insert trackingNumber + shipmentID used in migration from v1 -> v2.
    ///
    /// - Parameter req: Request
    /// - Returns: HTTP Status
    @Sendable
    func addMigratedShipments(req: Request) async throws -> HTTPStatus {
        _ = try req.auth.require(APIAdmin.self)

        let shipmentsToMigrate = try req.content.decode([MigratedShipment].self)

        for migratedShipment in shipmentsToMigrate {
            try await migratedShipment.save(on: req.db)
        }

        return .created
    }

    /// Find a migrated shipment from v1 by tracking number and return the ShipmentId to be used in this API.
    ///
    /// - Parameter req: Request
    /// - Returns: The shipment ID if it exists
    @Sendable
    func findMigratedShipment(req: Request) async throws -> ShipKitShipmentIdLookup {
        _ = try req.auth.require(APIUser.self)

        guard let _ = req.parameters.get("userId") else {
            throw Abort(.badRequest)
        }

        let findByTrackingRequest = try req.query.decode(ShipKitFindByTrackingRequest.self)
        let trackingNumber = findByTrackingRequest.trackingNumber

        guard let migratedShipment = try await MigratedShipment.query(on: req.db).filter(\.$trackingNumber == trackingNumber).first() else {
            throw Abort(.notFound)
        }

        return ShipKitShipmentIdLookup(shipmentId: migratedShipment.shipmentId)
    }
}
