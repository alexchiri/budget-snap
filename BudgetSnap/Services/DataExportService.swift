//
//  DataExportService.swift
//  BudgetSnap
//
//  Service for exporting and importing data with encryption
//

import Foundation
import SwiftData
import CryptoKit

class DataExportService {
    static let shared = DataExportService()

    private init() {}

    // MARK: - Export

    func exportData(
        transactions: [Transaction],
        budgets: [Budget],
        categories: [Category],
        password: String
    ) throws -> Data {
        // Create export data structure
        let exportData = ExportData(
            version: "1.0",
            exportDate: Date(),
            transactions: transactions.map { TransactionExport(from: $0) },
            budgets: budgets.map { BudgetExport(from: $0) },
            categories: categories.map { CategoryExport(from: $0) }
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(exportData)

        // Encrypt the data
        let encryptedData = try encrypt(data: jsonData, password: password)

        return encryptedData
    }

    // MARK: - Import

    func importData(from data: Data, password: String) throws -> ImportedData {
        // Decrypt the data
        let decryptedData = try decrypt(data: data, password: password)

        // Decode from JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportData.self, from: decryptedData)

        return ImportedData(
            transactions: exportData.transactions,
            budgets: exportData.budgets,
            categories: exportData.categories,
            version: exportData.version,
            exportDate: exportData.exportDate
        )
    }

    // MARK: - Encryption

    private func encrypt(data: Data, password: String) throws -> Data {
        // Derive key from password
        let salt = Data(UUID().uuidString.utf8)
        let key = try deriveKey(from: password, salt: salt)

        // Generate nonce
        let nonce = AES.GCM.Nonce()

        // Encrypt
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)

        // Combine salt, nonce, and encrypted data
        var combined = Data()
        combined.append(salt)
        combined.append(nonce.withUnsafeBytes { Data($0) })
        combined.append(sealedBox.ciphertext)
        combined.append(sealedBox.tag)

        return combined
    }

    private func decrypt(data: Data, password: String) throws -> Data {
        // Extract components
        let saltSize = UUID().uuidString.utf8.count
        let nonceSize = 12
        let tagSize = 16

        guard data.count > saltSize + nonceSize + tagSize else {
            throw ExportError.invalidData
        }

        let salt = data.prefix(saltSize)
        let nonceData = data.dropFirst(saltSize).prefix(nonceSize)
        let ciphertext = data.dropFirst(saltSize + nonceSize).dropLast(tagSize)
        let tag = data.suffix(tagSize)

        // Derive key
        let key = try deriveKey(from: password, salt: salt)

        // Create nonce
        let nonce = try AES.GCM.Nonce(data: nonceData)

        // Decrypt
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        return decryptedData
    }

    private func deriveKey(from password: String, salt: Data) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            throw ExportError.invalidPassword
        }

        // Use PBKDF2 to derive key from password
        let rounds = 100_000
        let keyData = try PBKDF2.deriveKey(
            password: passwordData,
            salt: salt,
            rounds: rounds,
            keyLength: 32
        )

        return SymmetricKey(data: keyData)
    }
}

// MARK: - PBKDF2 Implementation

enum PBKDF2 {
    static func deriveKey(password: Data, salt: Data, rounds: Int, keyLength: Int) throws -> Data {
        var derivedKey = Data(count: keyLength)
        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                password.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        password.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(rounds),
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        keyLength
                    )
                }
            }
        }

        guard result == kCCSuccess else {
            throw ExportError.encryptionFailed
        }

        return derivedKey
    }
}

// MARK: - Models

struct ExportData: Codable {
    let version: String
    let exportDate: Date
    let transactions: [TransactionExport]
    let budgets: [BudgetExport]
    let categories: [CategoryExport]
}

struct ImportedData {
    let transactions: [TransactionExport]
    let budgets: [BudgetExport]
    let categories: [CategoryExport]
    let version: String
    let exportDate: Date
}

struct TransactionExport: Codable {
    let id: UUID
    let date: Date
    let amount: Double
    let isIncome: Bool
    let merchant: String
    let description: String
    let categoryID: UUID?
    let accountID: UUID?
    let isReviewed: Bool
    let needsCorrection: Bool
    let originalOCRText: String
    let screenshotHash: String
    let createdAt: Date
    let lastModifiedAt: Date

    init(from transaction: Transaction) {
        self.id = transaction.id
        self.date = transaction.date
        self.amount = transaction.amount
        self.isIncome = transaction.isIncome
        self.merchant = transaction.merchant
        self.description = transaction.transactionDescription
        self.categoryID = transaction.category?.id
        self.accountID = transaction.account?.id
        self.isReviewed = transaction.isReviewed
        self.needsCorrection = transaction.needsCorrection
        self.originalOCRText = transaction.originalOCRText
        self.screenshotHash = transaction.screenshotHash
        self.createdAt = transaction.createdAt
        self.lastModifiedAt = transaction.lastModifiedAt
    }
}

struct BudgetExport: Codable {
    let id: UUID
    let categoryID: UUID?
    let monthYear: String
    let limit: Double
    let createdAt: Date
    let lastModifiedAt: Date

    init(from budget: Budget) {
        self.id = budget.id
        self.categoryID = budget.category?.id
        self.monthYear = budget.monthYear
        self.limit = budget.limit
        self.createdAt = budget.createdAt
        self.lastModifiedAt = budget.lastModifiedAt
    }
}

struct CategoryExport: Codable {
    let id: UUID
    let name: String
    let colorHex: String
    let icon: String
    let isDefault: Bool
    let createdAt: Date

    init(from category: Category) {
        self.id = category.id
        self.name = category.name
        self.colorHex = category.colorHex
        self.icon = category.icon
        self.isDefault = category.isDefault
        self.createdAt = category.createdAt
    }
}

enum ExportError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case invalidPassword

    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidData:
            return "The backup file is invalid or corrupted"
        case .invalidPassword:
            return "Invalid password"
        }
    }
}

// Import CommonCrypto for PBKDF2
import CommonCrypto
