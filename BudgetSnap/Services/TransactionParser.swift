//
//  TransactionParser.swift
//  BudgetSnap
//
//  Service for parsing OCR text to extract transaction details
//

import Foundation

class TransactionParser {
    static let shared = TransactionParser()

    private init() {}

    // Parse OCR text to extract transaction details
    func parseTransactions(from text: String) -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []
        let lines = text.components(separatedBy: .newlines)

        // Try to identify transaction patterns
        // Common patterns in banking apps:
        // - Date Amount Merchant Description
        // - Merchant Amount Date
        // - Date Merchant Amount

        var currentTransaction: ParsedTransaction?

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else { continue }

            // Try to extract amount
            if let amount = extractAmount(from: trimmedLine) {
                // Check if we have a date nearby
                let context = getLinesContext(lines: lines, currentIndex: index, range: 2)
                let date = extractDate(from: context)
                let merchant = extractMerchant(from: trimmedLine, excludingAmount: amount)

                let transaction = ParsedTransaction(
                    date: date,
                    amount: abs(amount), // Store as positive
                    merchant: merchant,
                    description: trimmedLine,
                    confidence: calculateConfidence(date: date, amount: amount, merchant: merchant),
                    originalText: trimmedLine
                )

                // Avoid duplicates in same parse session
                if !isDuplicate(transaction: transaction, in: transactions) {
                    transactions.append(transaction)
                }
            }
        }

        return transactions
    }

    // Extract amount from text (handles various formats)
    private func extractAmount(from text: String) -> Double? {
        // Patterns: $123.45, 123.45, $123, -$123.45, (123.45)
        let patterns = [
            "\\$?([0-9,]+\\.\\d{2})",           // $123.45 or 123.45
            "\\$?([0-9,]+)",                     // $123 or 123
            "\\(\\$?([0-9,]+\\.?\\d*)\\)",      // ($123.45) - negative
            "-\\$?([0-9,]+\\.?\\d*)"            // -$123.45 - negative
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {

                let amountString = String(text[range]).replacingOccurrences(of: ",", with: "")
                if let amount = Double(amountString) {
                    // If pattern includes parentheses or minus, it's negative
                    return text.contains("(") || text.contains("-") ? -amount : amount
                }
            }
        }

        return nil
    }

    // Extract date from text (handles various formats)
    private func extractDate(from text: String) -> Date? {
        let dateFormats = [
            "MM/dd/yyyy", "MM/dd/yy",
            "dd/MM/yyyy", "dd/MM/yy",
            "yyyy-MM-dd",
            "MMM dd, yyyy", "MMM dd",
            "MMMM dd, yyyy", "MMMM dd",
            "dd MMM yyyy", "dd MMM"
        ]

        let datePatterns = [
            "\\d{1,2}/\\d{1,2}/\\d{2,4}",      // 12/31/2024 or 31/12/24
            "\\d{4}-\\d{2}-\\d{2}",             // 2024-12-31
            "[A-Za-z]{3}\\s+\\d{1,2}(?:,\\s+\\d{4})?",  // Dec 31, 2024 or Dec 31
            "[A-Za-z]+\\s+\\d{1,2}(?:,\\s+\\d{4})?"     // December 31, 2024
        ]

        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {

                let dateString = String(text[range])

                for format in dateFormats {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    formatter.locale = Locale(identifier: "en_US_POSIX")

                    if let date = formatter.date(from: dateString) {
                        // If year is missing, assume current year
                        if !format.contains("yyyy") && !format.contains("yy") {
                            let calendar = Calendar.current
                            let components = calendar.dateComponents([.month, .day], from: date)
                            if let dateWithYear = calendar.date(from: DateComponents(
                                year: calendar.component(.year, from: Date()),
                                month: components.month,
                                day: components.day
                            )) {
                                return dateWithYear
                            }
                        }
                        return date
                    }
                }
            }
        }

        // If no date found, return today's date as fallback
        return Date()
    }

    // Extract merchant name from text
    private func extractMerchant(from text: String, excludingAmount amount: Double) -> String {
        var merchant = text

        // Remove amount string
        if let regex = try? NSRegularExpression(pattern: "\\$?[0-9,]+\\.?\\d*", options: []) {
            merchant = regex.stringByReplacingMatches(
                in: merchant,
                options: [],
                range: NSRange(merchant.startIndex..., in: merchant),
                withTemplate: ""
            )
        }

        // Remove common date patterns
        let datePatterns = ["\\d{1,2}/\\d{1,2}/\\d{2,4}", "\\d{4}-\\d{2}-\\d{2}"]
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                merchant = regex.stringByReplacingMatches(
                    in: merchant,
                    options: [],
                    range: NSRange(merchant.startIndex..., in: merchant),
                    withTemplate: ""
                )
            }
        }

        // Clean up
        merchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        merchant = merchant.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return merchant.isEmpty ? "Unknown Merchant" : merchant
    }

    // Get context lines around current line
    private func getLinesContext(lines: [String], currentIndex: Int, range: Int) -> String {
        let start = max(0, currentIndex - range)
        let end = min(lines.count - 1, currentIndex + range)
        return lines[start...end].joined(separator: "\n")
    }

    // Calculate confidence score for parsed transaction
    private func calculateConfidence(date: Date?, amount: Double, merchant: String) -> Double {
        var confidence = 0.0

        // Amount is always present (required for detection)
        confidence += 0.4

        // Date presence
        if date != nil {
            confidence += 0.3
        }

        // Merchant quality
        if !merchant.isEmpty && merchant != "Unknown Merchant" {
            confidence += 0.3
            // Bonus for reasonable merchant name length
            if merchant.count > 3 && merchant.count < 50 {
                confidence += 0.1
            }
        }

        return min(confidence, 1.0)
    }

    // Check if transaction is duplicate in current batch
    private func isDuplicate(transaction: ParsedTransaction, in transactions: [ParsedTransaction]) -> Bool {
        for existing in transactions {
            if abs(existing.amount - transaction.amount) < 0.01 &&
               existing.merchant == transaction.merchant &&
               Calendar.current.isDate(existing.date ?? Date(), inSameDayAs: transaction.date ?? Date()) {
                return true
            }
        }
        return false
    }
}

// MARK: - Models

struct ParsedTransaction {
    let date: Date?
    let amount: Double
    let merchant: String
    let description: String
    let confidence: Double
    let originalText: String

    var needsReview: Bool {
        confidence < 0.7
    }
}
