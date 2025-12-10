//
//  Transaction.swift
//  BudgetSnap
//
//  Model for financial transactions extracted from screenshots
//

import Foundation
import SwiftData

@available(iOS 17.0, *)
@Model
final class Transaction {
    var id: UUID
    var date: Date
    var amount: Double
    var isIncome: Bool // true for income (+), false for expense (-)
    var merchant: String
    var transactionDescription: String
    var category: Category?
    var account: Account?
    var isReviewed: Bool
    var needsCorrection: Bool
    var originalOCRText: String
    var screenshotHash: String // For duplicate detection
    var createdAt: Date
    var lastModifiedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        amount: Double,
        isIncome: Bool = false,
        merchant: String,
        transactionDescription: String = "",
        category: Category? = nil,
        account: Account? = nil,
        isReviewed: Bool = false,
        needsCorrection: Bool = false,
        originalOCRText: String = "",
        screenshotHash: String = "",
        createdAt: Date = Date(),
        lastModifiedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.isIncome = isIncome
        self.merchant = merchant
        self.transactionDescription = transactionDescription
        self.category = category
        self.account = account
        self.isReviewed = isReviewed
        self.needsCorrection = needsCorrection
        self.originalOCRText = originalOCRText
        self.screenshotHash = screenshotHash
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }

    // Computed property to get month/year for grouping
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    // Signed amount (positive for income, negative for expense)
    var signedAmount: Double {
        return isIncome ? amount : -amount
    }

    // Format amount as currency
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        let value = isIncome ? amount : -amount
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}
