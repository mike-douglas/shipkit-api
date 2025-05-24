//
//  ShipkitSubstatus.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/24/25.
//

/// Represents a more detailed status for a shipment being tracked
enum ShipkitSubstatus: String, RawRepresentable, CaseIterable, Codable {
    case delivered_001
    case delivered_002
    case delivered_003
    case delivered_004
    case availableForPickup_001
    case exception_001
    case exception_002
    case exception_003
    case exception_004
    case exception_005
    case exception_006
    case exception_007
    case exception_008
    case exception_009
    case exception_010
    case exception_011
    case exception_012
    case exception_013
    case attemptFail_001
    case attemptFail_002
    case attemptFail_003
    case inTransit_001
    case inTransit_002
    case inTransit_003
    case inTransit_004
    case inTransit_005
    case inTransit_006
    case inTransit_007
    case inTransit_008
    case inTransit_009
    case infoReceived_001
    case outForDelivery_001
    case outForDelivery_003
    case outForDelivery_004
    case pending_001
    case pending_002
    case pending_003
    case pending_004
    case pending_005
    case pending_006
    case expired_001
    case unknown
}
