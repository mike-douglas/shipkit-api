//
//  ModelExtensions.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/23/25.
//

import AfterShip

private extension String {
    var withLowercasedFirstCharacter: String {
        guard let firstCharacter = first else {
            return self
        }

        return String(firstCharacter).lowercased() + dropFirst()
    }
}

extension ASTracking {
    func toDTO() -> ShipkitShipment {
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
    func toDTO() -> ShipkitShipmentUpdate {
        .init(
            id: .init(),
            title: message,
            comment: "",
            status: ShipkitStatus(rawValue: tag.withLowercasedFirstCharacter) ?? .unknown,
            substatus: ShipkitSubstatus(rawValue: subtag.withLowercasedFirstCharacter) ?? .unknown,
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
    func toDTO() -> ShipkitCarrier {
        .init(name: name, code: slug)
    }
}
