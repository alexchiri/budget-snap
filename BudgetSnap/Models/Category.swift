//
//  Category.swift
//  BudgetSnap
//
//  Model for spending categories
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Category {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    var isDefault: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]?

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        icon: String = "folder",
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.isDefault = isDefault
        self.createdAt = createdAt
    }

    // Convert hex color to SwiftUI Color
    var color: Color {
        Color(colorHex)
    }

    // Default categories to seed the app
    static func createDefaultCategories() -> [Category] {
        return [
            Category(name: "Groceries", colorHex: "#34C759", icon: "cart", isDefault: true),
            Category(name: "Dining", colorHex: "#FF9500", icon: "fork.knife", isDefault: true),
            Category(name: "Transportation", colorHex: "#007AFF", icon: "car", isDefault: true),
            Category(name: "Entertainment", colorHex: "#AF52DE", icon: "tv", isDefault: true),
            Category(name: "Shopping", colorHex: "#FF2D55", icon: "bag", isDefault: true),
            Category(name: "Bills & Utilities", colorHex: "#5856D6", icon: "bolt", isDefault: true),
            Category(name: "Healthcare", colorHex: "#FF3B30", icon: "heart", isDefault: true),
            Category(name: "Other", colorHex: "#8E8E93", icon: "ellipsis.circle", isDefault: true)
        ]
    }
}
