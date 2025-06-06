//
//  ModelExtensions.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/23/25.
//

import AfterShip
import struct Foundation.URL
import ShipKitTypes

private extension String {
    var withLowercasedFirstCharacter: String {
        guard let firstCharacter = first else {
            return self
        }

        return String(firstCharacter).lowercased() + dropFirst()
    }
}

extension ASTracking {
    func toDTO() -> ShipKitShipment {
        .init(
            id: id,
            title: title,
            trackingNumber: trackingNumber,
            carrier: slug,
            updates: checkpoints.map { $0.toDTO() },
            deliveryDate: courierEstimatedDeliveryDate?.estimatedDeliveryDate,
            timestamp: updatedAt
        )
    }
}

extension ASCheckpoint {
    func toDTO() -> ShipKitShipmentUpdate {
        .init(
            id: .init(),
            title: message,
            comment: "",
            status: ShipKitStatus(rawValue: tag.withLowercasedFirstCharacter) ?? .unknown,
            substatus: ShipKitSubstatus(rawValue: subtag.withLowercasedFirstCharacter) ?? .unknown,
            city: city,
            state: state,
            zip: zip,
            country: countryRegion,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude,
            timestamp: checkpointTime
        )
    }
}

extension ASCourier {
    func toDTO() -> ShipKitCarrier {
        .init(
            name: name,
            code: slug,
            summary: otherName ?? name,
            url: webUrl != nil ? URL(string: webUrl!) : nil
        )
    }
}
