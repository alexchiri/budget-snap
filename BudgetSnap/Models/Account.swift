import Foundation
import SwiftData
import SwiftUI

@Model
final class Account {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    var createdAt: Date
    var lastModifiedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]?

    init(name: String, colorHex: String = "#007AFF", icon: String = "banknote") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.createdAt = Date()
        self.lastModifiedAt = Date()
    }

    var color: Color {
        Color(hex: colorHex)
    }

    // Computed balance from all transactions
    var balance: Double {
        guard let transactions = transactions else { return 0 }
        return transactions.reduce(0) { $0 + $1.signedAmount }
    }

    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: balance)) ?? "$0.00"
    }
}
