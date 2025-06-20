//
//  TestShipKitShipments.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 6/20/25.
//

import Foundation
import ShipKitTypes

// MARK: - Test Shipments Data

let testShipments: [ShipKitShipment] = [
    // 1. Delivered iPhone from Apple
    ShipKitShipment(
        id: UUID().uuidString,
        title: "iPhone 15 Pro Max",
        trackingNumber: "1Z999AA1234567890",
        carrier: ShipKitCarrier(
            name: "UPS",
            code: "ups",
            summary: "United Parcel Service",
            url: URL(string: "https://www.ups.com")
        ),
        updates: [
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Package Delivered",
                comment: "Your package was delivered to the front door",
                status: .delivered,
                substatus: .delivered_003,
                city: "Cupertino",
                state: "CA",
                zip: "95014",
                country: "US",
                latitude: 37.3230,
                longitude: -122.0322,
                timestamp: Date(timeIntervalSinceNow: -3600) // 1 hour ago
            ),
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Out for Delivery",
                comment: "Package is out for delivery and will arrive today",
                status: .outForDelivery,
                substatus: .outForDelivery_001,
                city: "Cupertino",
                state: "CA",
                zip: "95014",
                country: "US",
                latitude: 37.3230,
                longitude: -122.0322,
                timestamp: Date(timeIntervalSinceNow: -14400) // 4 hours ago
            ),
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Package Arrived at Facility",
                comment: "Arrived at UPS facility",
                status: .inTransit,
                substatus: .inTransit_003,
                city: "San Jose",
                state: "CA",
                zip: "95110",
                country: "US",
                latitude: 37.3382,
                longitude: -121.8863,
                timestamp: Date(timeIntervalSinceNow: -86400) // 1 day ago
            ),
        ],
        deliveryDate: Date(timeIntervalSinceNow: -3600),
        timestamp: Date(timeIntervalSinceNow: -172_800) // 2 days ago
    ),

    // 2. In Transit Amazon Package
    ShipKitShipment(
        id: UUID().uuidString,
        title: "Wireless Headphones & Phone Case",
        trackingNumber: "TBA123456789012",
        carrier: ShipKitCarrier(
            name: "Amazon Logistics",
            code: "amzl",
            summary: "Amazon's delivery service",
            url: URL(string: "https://www.amazon.com")
        ),
        updates: [
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Package Departed Facility",
                comment: "Your package has left our fulfillment center and is on its way",
                status: .inTransit,
                substatus: .inTransit_007,
                city: "Phoenix",
                state: "AZ",
                zip: "85043",
                country: "US",
                latitude: 33.3833,
                longitude: -112.0446,
                timestamp: Date(timeIntervalSinceNow: -7200) // 2 hours ago
            ),
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Package Processed",
                comment: "Package received and processed at fulfillment center",
                status: .inTransit,
                substatus: .inTransit_002,
                city: "Phoenix",
                state: "AZ",
                zip: "85043",
                country: "US",
                latitude: 33.3833,
                longitude: -112.0446,
                timestamp: Date(timeIntervalSinceNow: -21600) // 6 hours ago
            ),
        ],
        deliveryDate: Date(timeIntervalSinceNow: 86400), // Tomorrow
        timestamp: Date(timeIntervalSinceNow: -21600)
    ),

    // 3. Failed Delivery Attempt - FedEx
    ShipKitShipment(
        id: UUID().uuidString,
        title: "Laptop Computer",
        trackingNumber: "7712345678901234",
        carrier: ShipKitCarrier(
            name: "FedEx",
            code: "fedex",
            summary: "Federal Express Corporation",
            url: URL(string: "https://www.fedex.com")
        ),
        updates: [
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Delivery Attempt Failed",
                comment: "Customer not available or business closed",
                status: .attemptFail,
                substatus: .attemptFail_002,
                city: "Phoenix",
                state: "AZ",
                zip: "85018",
                country: "US",
                latitude: 33.4484,
                longitude: -112.0740,
                timestamp: Date(timeIntervalSinceNow: -1800) // 30 minutes ago
            ),
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Out for Delivery",
                comment: "On FedEx vehicle for delivery",
                status: .outForDelivery,
                substatus: .outForDelivery_001,
                city: "Phoenix",
                state: "AZ",
                zip: "85018",
                country: "US",
                latitude: 33.4484,
                longitude: -112.0740,
                timestamp: Date(timeIntervalSinceNow: -25200) // 7 hours ago
            ),
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "At Local FedEx Facility",
                comment: "Arrived at FedEx Ground facility",
                status: .inTransit,
                substatus: .inTransit_003,
                city: "Phoenix",
                state: "AZ",
                zip: "85043",
                country: "US",
                latitude: 33.3833,
                longitude: -112.0446,
                timestamp: Date(timeIntervalSinceNow: -108_000) // 30 hours ago
            ),
        ],
        deliveryDate: Date(timeIntervalSinceNow: 86400), // Tomorrow (rescheduled)
        timestamp: Date(timeIntervalSinceNow: -345_600) // 4 days ago
    ),

    // 4. International Package with Customs Delay
    ShipKitShipment(
        id: UUID().uuidString,
        title: "Electronics from Tokyo",
        trackingNumber: "EJ123456789JP",
        carrier: ShipKitCarrier(
            name: "Japan Post",
            code: "japan-post",
            summary: "Japan Post Service",
            url: URL(string: "https://www.post.japanpost.jp")
        ),
        updates: [
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Customs Clearance Delayed",
                comment: "Package held at customs for additional inspection",
                status: .exception,
                substatus: .exception_004,
                city: "Los Angeles",
                state: "CA",
                zip: "90009",
                country: "US",
                latitude: 33.9425,
                longitude: -118.4081,
                timestamp: Date(timeIntervalSinceNow: -43200) // 12 hours ago
            ),
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Arrived at Customs",
                comment: "Package arrived at US customs facility",
                status: .inTransit,
                substatus: .inTransit_006,
                city: "Los Angeles",
                state: "CA",
                zip: "90009",
                country: "US",
                latitude: 33.9425,
                longitude: -118.4081,
                timestamp: Date(timeIntervalSinceNow: -129_600) // 36 hours ago
            ),
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Departed from Tokyo",
                comment: "Left international sorting facility",
                status: .inTransit,
                substatus: .inTransit_007,
                city: "Tokyo",
                state: nil,
                zip: "144-0041",
                country: "JP",
                latitude: 35.6762,
                longitude: 139.6503,
                timestamp: Date(timeIntervalSinceNow: -259_200) // 3 days ago
            ),
        ],
        deliveryDate: nil, // Unknown due to customs delay
        timestamp: Date(timeIntervalSinceNow: -432_000) // 5 days ago
    ),

    // 5. Available for Pickup at Local Store
    ShipKitShipment(
        id: UUID().uuidString,
        title: "Best Buy Order - Gaming Headset",
        trackingNumber: "BBY9876543210",
        carrier: ShipKitCarrier(
            name: "Best Buy",
            code: "bestbuy",
            summary: "Best Buy Store Pickup",
            url: URL(string: "https://www.bestbuy.com")
        ),
        updates: [
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Ready for Pickup",
                comment: "Your order is ready for pickup at Best Buy Arrowhead",
                status: .availableForPickup,
                substatus: .availableForPickup_001,
                city: "Glendale",
                state: "AZ",
                zip: "85308",
                country: "US",
                latitude: 33.6292,
                longitude: -112.2640,
                timestamp: Date(timeIntervalSinceNow: -5400) // 1.5 hours ago
            ),
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Order Processing",
                comment: "Your order is being prepared",
                status: .inTransit,
                substatus: .inTransit_001,
                city: "Phoenix",
                state: "AZ",
                zip: "85043",
                country: "US",
                latitude: 33.3833,
                longitude: -112.0446,
                timestamp: Date(timeIntervalSinceNow: -10800) // 3 hours ago
            ),
            ShipKitShipmentUpdate(
                id: UUID().uuidString,
                title: "Order Confirmed",
                comment: "Order received and confirmed",
                status: .infoReceived,
                substatus: .infoReceived_001,
                city: "Phoenix",
                state: "AZ",
                zip: "85043",
                country: "US",
                latitude: 33.3833,
                longitude: -112.0446,
                timestamp: Date(timeIntervalSinceNow: -21600) // 6 hours ago
            ),
        ],
        deliveryDate: nil, // Pickup, not delivery
        timestamp: Date(timeIntervalSinceNow: -21600)
    ),
]
