//
//  CeleryClient.swift
//  ShipKitApi
//
//  Created by Mike Douglas on 5/30/25.
//

import Foundation
import Redis

// Define the structures for the message protocol
struct CeleryMessage: Codable {
    let properties: MessageProperties
    let headers: MessageHeaders
    let body: MessageBody
}

struct MessageProperties: Codable {
    let correlationId: UUID
    let contentType: String
    let contentEncoding: String
    let replyTo: String?
}

struct MessageHeaders: Codable {
    let lang: String
    let task: String
    let id: UUID
    let rootId: UUID?
    let parentId: UUID?
    let group: UUID?
    let meth: String?
    let eta: String?
    let expires: String?
    let retries: Int?
    let timelimit: [Double]?
    let argsrepr: String
    let kwargsrepr: String
    let origin: String
}

struct MessageBody: Codable {
    let args: [AnyCodable] // Use AnyCodable for dynamic types
    let kwargs: [String: AnyCodable] // Use AnyCodable for dynamic types
    let embed: Embed?
}

struct Embed: Codable {
    let errbacks: [String]?
    let chain: [String]?
    let chord: String?
    let callbacks: [String]?
}

// A wrapper for dynamic types
struct AnyCodable: Codable {
    var value: Any

    init<T>(_ value: T) {
        self.value = value
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// Celery Client Actor
actor CeleryClient {
    let redisClient: any RedisClient

    init(redisClient: any RedisClient) {
        self.redisClient = redisClient
    }

    func sendTask(task: String, args: [Any], kwargs: [String: Any], correlationId: UUID) async throws {
        let properties = MessageProperties(
            correlationId: correlationId,
            contentType: "application/json",
            contentEncoding: "utf-8",
            replyTo: nil
        )

        let headers = MessageHeaders(
            lang: "swift",
            task: task,
            id: correlationId,
            rootId: nil,
            parentId: nil,
            group: nil,
            meth: nil,
            eta: nil,
            expires: nil,
            retries: nil,
            timelimit: nil,
            argsrepr: String(describing: args),
            kwargsrepr: String(describing: kwargs),
            origin: "\(ProcessInfo.processInfo.processIdentifier)@\(Host.current().localizedName ?? "localhost")"
        )

        let body = MessageBody(
            args: args.map { AnyCodable($0) },
            kwargs: kwargs.mapValues { AnyCodable($0) },
            embed: nil
        )

        let message = CeleryMessage(properties: properties, headers: headers, body: body)

        let jsonData = try JSONEncoder().encode(message)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Send the message to Redis
        redisClient.publish(jsonString, to: "celery")
    }
}

// Usage Example
// let redisClient = RedisClient() // Initialize your Redis client
// let celeryClient = CeleryClient(redisClient: redisClient)
//
// let taskId = UUID()
// @MainActor let args: [Any] = [2, 2]
// @MainActor let kwargs: [String: Any] = [:]
//
// Task {
//    do {
//        try await celeryClient.sendTask(task: "proj.tasks.add", args: args, kwargs: kwargs, correlationId: taskId)
//        print("Task sent successfully!")
//    } catch {
//        print("Failed to send task: \(error)")
//    }
// }
