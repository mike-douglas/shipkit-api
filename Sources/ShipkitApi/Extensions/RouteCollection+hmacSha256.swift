//
//  RouteCollection+hmacSha256.swift
//  ShipkitApi
//
//  Created by Mike Douglas on 5/26/25.
//

import CryptoKit
import Vapor

extension RouteCollection {
    /// Generate a signature used to validate the authenticity of a request
    ///
    /// - Parameters:
    ///   - data: Data to sign
    ///   - secret: Secret to sign it with
    /// - Returns: A base64 string
    func hmacSha256(data: String, secret: String) -> String? {
        let key = SymmetricKey(data: Data(secret.utf8))

        guard let dataToSign = data.data(using: .utf8) else {
            return nil
        }

        let signature = HMAC<SHA256>.authenticationCode(for: dataToSign, using: key)
        let hmacData = Data(signature)

        return hmacData.base64EncodedString()
    }
}
