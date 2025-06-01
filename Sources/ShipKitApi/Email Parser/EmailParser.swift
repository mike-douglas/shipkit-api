//
//  EmailParser.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 6/1/25.
//

import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
import Orinoco

struct TrackingInfo {
    let carrier: String?
    let trackingNumber: String?
    let title: String?
}

struct ChatGPTShipmentTrackingAssistantResponse: Codable {
    struct ShipmentFunction: Codable {
        struct ShipmentFunctionArguments: Codable {
            let carrier: String?
            let itemName: String?
            let trackingNumber: String?

            enum CodingKeys: String, CodingKey {
                case carrier
                case itemName = "item_name"
                case trackingNumber = "tracking_number"
            }
        }

        let name: String
        let arguments: ShipmentFunctionArguments
    }

    let functions: [ShipmentFunction]?
}

struct EmailParser {
    private let client: OrinocoClient

    init(clientUrl: URL) {
        client = .init(baseURL: clientUrl)
    }

    func detectTrackingFromEmail(_ email: String) async throws -> [TrackingInfo]? {
        guard let taskId = try await client.runTask(
            "run_chatgpt_assistant_prompt",
            kwargs: [
                "prompt": "Get the tracking information from the email below:\n\n\(email)",
                "assistant_id": "asst_JKdtEQSiXTyAxTqkRYgsBhGv",
            ]
        ) else {
            return nil
        }

        guard let response: ChatGPTShipmentTrackingAssistantResponse = try await client.getSuccessResult(
            taskId,
            withTimeout: 30
        ) else {
            return nil
        }

        if let functions = response.functions {
            return functions.compactMap {
                guard let trackingNumber = $0.arguments.trackingNumber else {
                    return nil
                }

                if trackingNumber.isEmpty {
                    return nil
                }

                let itemName = $0.arguments.itemName ?? trackingNumber

                return TrackingInfo(
                    carrier: "",
                    trackingNumber: trackingNumber,
                    title: itemName
                )
            }
        } else {
            return nil
        }
    }
}
