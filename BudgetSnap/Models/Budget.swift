//
//  Budget.swift
//  BudgetSnap
//
//  Model for monthly budget limits per category
//

import Foundation
import SwiftData

@Model
final class Budget {
    var id: UUID
    var category: Category?
    var monthYear: String // Format: "yyyy-MM"
    var limit: Double
    var createdAt: Date
    var lastModifiedAt: Date

    init(
        id: UUID = UUID(),
        category: Category? = nil,
        monthYear: String,
        limit: Double,
        createdAt: Date = Date(),
        lastModifiedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.monthYear = monthYear
        self.limit = limit
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }

    // Format limit as currency
    var formattedLimit: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: limit)) ?? "$\(limit)"
    }

    // Get display name for month/year
    var displayMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        if let date = formatter.date(from: monthYear) {
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        return monthYear
    }

    // Create budget for current month
    static func currentMonthYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    // Get next month's identifier
    static func nextMonthYear(from monthYear: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: monthYear),
              let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: date) else {
            return nil
        }
        return formatter.string(from: nextMonth)
    }

    // Get previous month's identifier
    static func previousMonthYear(from monthYear: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: monthYear),
              let prevMonth = Calendar.current.date(byAdding: .month, value: -1, to: date) else {
            return nil
        }
        return formatter.string(from: prevMonth)
    }
}
