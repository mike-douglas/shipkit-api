//
//  UserAuthenticator.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/27/25.
//

import Vapor

struct APIUser: Authenticatable {}
struct APIAdmin: Authenticatable {}
struct APIMetricsUser: Authenticatable {}

struct UserAuthenticator: AsyncBearerAuthenticator {
    typealias User = APIUser

    private let userToken: String
    private let adminToken: String
    private let metricsToken: String

    init() {
        guard let userToken = Environment.process.USER_TOKEN else {
            fatalError("USER_TOKEN environment variable not set")
        }

        guard let adminToken = Environment.process.ADMIN_TOKEN else {
            fatalError("ADMIN_TOKEN environment variable not set")
        }

        guard let metricsToken = Environment.process.METRICS_TOKEN else {
            fatalError("METRICS_TOKEN environment variable not set")
        }

        self.userToken = userToken
        self.adminToken = adminToken
        self.metricsToken = metricsToken
    }

    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        switch bearer.token {
        case userToken:
            request.auth.login(APIUser())
        case adminToken:
            request.auth.login(APIAdmin())
        case metricsToken:
            request.auth.login(APIMetricsUser())
        default:
            throw Abort(.unauthorized)
        }
    }
}
